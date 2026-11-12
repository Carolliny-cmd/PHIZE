import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../analise/data/consentimento_repository_local.dart';
import '../../analise/data/tutorial_repository_local.dart';
import '../../auth/data/auth_error_mapper.dart';
import '../../auth/data/credencial_google.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/conta_repository.dart';
import '../domain/exclusao_conta.dart';
import 'compartilhador_arquivo_nativo.dart';
import 'pendencia_exclusao.dart';

/// Sem este limite, a escrita no Firestore sem conexão deixaria a tela de
/// exclusão carregando para sempre.
const Duration limiteEtapaExclusao = Duration(seconds: 20);

/// Limite de operações em um lote de escrita do Firestore.
const int tamanhoLoteExclusao = 500;

class ContaRepositoryFirebase implements ContaRepository {
  ContaRepositoryFirebase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    PendenciaExclusao? pendencia,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _pendencia = pendencia ?? PendenciaExclusao();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final PendenciaExclusao _pendencia;

  User get _usuario {
    final usuario = _auth.currentUser;
    if (usuario == null) throw StateError('Sem usuário autenticado.');
    return usuario;
  }

  DocumentReference<Map<String, dynamic>> _perfil(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<PerfilConta> carregarPerfil() async {
    final usuario = _usuario;
    final documento = await _perfil(usuario.uid)
        .get(const GetOptions(source: Source.server));
    final criadaEm = documento.data()?['createdAt'];
    final nome = documento.data()?['nomeExibicao'];
    return PerfilConta(
      uid: usuario.uid,
      email: usuario.email,
      criadaEm: criadaEm is Timestamp ? criadaEm.toDate() : null,
      nomeExibicao: nome is String ? nome : null,
    );
  }

  @override
  IdentidadeConta get identidade => _identidadeDe(_usuario);

  @override
  Future<IdentidadeConta> atualizarIdentidade() async {
    await _usuario.reload();
    return _identidadeDe(_usuario);
  }

  @override
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final usuario = _usuario;
    await _confirmarSenha(
      usuario,
      senhaAtual,
      mensagemSenhaErrada: 'Senha atual incorreta.',
    );
    try {
      await usuario.updatePassword(novaSenha);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapearErroAutenticacao(e));
    }
  }

  @override
  Future<void> reenviarVerificacao() async {
    try {
      await _usuario.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(switch (e.code) {
        'too-many-requests' =>
          'Já enviamos vários e-mails. Aguarde alguns minutos antes de pedir '
              'outro.',
        _ => mapearErroAutenticacao(e),
      });
    }
  }

  static IdentidadeConta _identidadeDe(User usuario) {
    final provedores = usuario.providerData.map((p) => p.providerId).toSet();
    return IdentidadeConta(
      email: usuario.email,
      emailVerificado: usuario.emailVerified,
      entraComSenha: provedores.contains(EmailAuthProvider.PROVIDER_ID),
      entraComGoogle: provedores.contains(GoogleAuthProvider.PROVIDER_ID),
    );
  }

  @override
  Future<void> salvarNomeExibicao(String? nome) async {
    // Só este campo muda; as regras do Firestore recusam qualquer outro.
    await _perfil(_usuario.uid)
        .update({'nomeExibicao': nome ?? FieldValue.delete()});
  }

  @override
  bool get exigeSenha => _usuario.providerData.any(
    (provedor) => provedor.providerId == EmailAuthProvider.PROVIDER_ID,
  );

  @override
  Future<void> excluirConta({String? senha}) async {
    final usuario = _usuario;
    final uid = usuario.uid;

    // A senha vem antes de tudo porque o Firebase Auth só remove a credencial
    // com login recente. A remoção da credencial não tem limite de tempo: ela
    // falha sozinha sem rede, e desistir de esperar não a cancela, o que
    // mandaria ao bloqueio uma conta que já deixou de existir.
    await executarExclusaoConta(
      confirmarSenha: () => senha == null
          ? _confirmarPeloGoogle(usuario)
          : _confirmarSenha(usuario, senha),
      lerDocumentos: () => _lerAnalises(uid).timeout(limiteEtapaExclusao),
      registrarPendencia: () => _pendencia.registrar(uid),
      removerDocumentos: (analises) =>
          _removerDocumentos(uid, analises).timeout(limiteEtapaExclusao),
      removerCredencial: usuario.delete,
      concluir: _pendencia.limpar,
    );
    await CompartilhadorArquivoNativo.removerCopiaLocal();
    try {
      await ConsentimentoRepositoryLocal.removerDe(uid);
    } catch (_) {
      // A conta já não existe; a marca não identifica ninguém.
    }
    try {
      await TutorialRepositoryLocal.removerDe(uid);
    } catch (_) {
      // Idem: só a marca de tutorial visto (RF13).
    }
  }

  @override
  Future<bool> exclusaoPendente() async {
    final uid = _auth.currentUser?.uid;
    return uid != null && await _pendencia.existePara(uid);
  }

  Future<void> _confirmarPeloGoogle(User usuario) async {
    try {
      final credencial = await obterCredencialGoogle();
      if (credencial == null) {
        throw const AuthException('Confirmação cancelada. Nada foi apagado.');
      }
      await usuario.reauthenticateWithCredential(credencial);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapearErroAutenticacao(e));
    }
  }

  Future<void> _confirmarSenha(
    User usuario,
    String senha, {
    String mensagemSenhaErrada = 'Senha incorreta.',
  }) async {
    final email = usuario.email;
    if (email == null) throw const AuthException(_mensagemFalhaConfirmacao);
    try {
      await usuario.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: senha),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(switch (e.code) {
        'wrong-password' || 'invalid-credential' => mensagemSenhaErrada,
        _ => mapearErroAutenticacao(e),
      });
    }
  }

  /// Consulta o servidor, e não o cache do aparelho, para que nenhum registro
  /// fique para trás.
  Future<List<DocumentReference<Map<String, dynamic>>>> _lerAnalises(
    String uid,
  ) async {
    final analises = await _perfil(uid)
        .collection('analises')
        .get(const GetOptions(source: Source.server));
    return analises.docs.map((doc) => doc.reference).toList();
  }

  Future<void> _removerDocumentos(
    String uid,
    List<DocumentReference<Map<String, dynamic>>> analises,
  ) async {
    for (var i = 0; i < analises.length; i += tamanhoLoteExclusao) {
      final lote = _firestore.batch();
      analises.skip(i).take(tamanhoLoteExclusao).forEach(lote.delete);
      await lote.commit();
    }
    await _perfil(uid).delete();
  }

  static const String _mensagemFalhaConfirmacao =
      'Não foi possível confirmar sua senha. Tente novamente.';
}
