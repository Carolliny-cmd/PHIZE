import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.erroCadastro, this.erroLogin, this.erroRedefinicaoSenha});

  final AuthException? erroCadastro;
  final AuthException? erroLogin;
  final AuthException? erroRedefinicaoSenha;

  String? emailCadastrado;
  String? emailLogado;
  String? emailRedefinicaoSolicitado;
  bool saiu = false;

  /// `null` simula a desistência na escolha da conta Google.
  bool? resultadoGoogle = true;
  AuthException? erroGoogle;
  int entradasGoogle = 0;

  @override
  Future<void> cadastrar({required String email, required String senha}) async {
    if (erroCadastro != null) throw erroCadastro!;
    emailCadastrado = email;
  }

  @override
  Future<void> entrar({required String email, required String senha}) async {
    if (erroLogin != null) throw erroLogin!;
    emailLogado = email;
  }

  @override
  Future<bool> entrarComGoogle() async {
    entradasGoogle++;
    if (erroGoogle != null) throw erroGoogle!;
    return resultadoGoogle ?? false;
  }

  @override
  Future<void> enviarEmailRedefinicaoSenha(String email) async {
    if (erroRedefinicaoSenha != null) throw erroRedefinicaoSenha!;
    emailRedefinicaoSolicitado = email;
  }

  @override
  Future<void> sair() async {
    saiu = true;
  }
}
