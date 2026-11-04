import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consentimento_repository.dart';

/// Guarda no aparelho a versão do aviso aceita por cada usuário. Reinstalar o
/// app, ou entrar em outro aparelho, mostra o aviso de novo.
class ConsentimentoRepositoryLocal implements ConsentimentoRepository {
  ConsentimentoRepositoryLocal({String? Function()? uidAtual})
    : _uidAtual = uidAtual ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final String? Function() _uidAtual;

  static String chavePara(String uid) => 'consentimento_analise_$uid';

  static Future<void> removerDe(String uid) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(chavePara(uid));
  }

  String get _chave {
    final uid = _uidAtual();
    if (uid == null) throw StateError('Sem usuário autenticado.');
    return chavePara(uid);
  }

  @override
  Future<bool> aceito() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getInt(_chave) == versaoConsentimentoAnalise;
  }

  @override
  Future<void> aceitar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setInt(_chave, versaoConsentimentoAnalise);
  }

  @override
  Future<void> revogar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chave);
  }
}
