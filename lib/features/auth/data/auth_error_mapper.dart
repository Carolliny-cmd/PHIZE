import 'package:firebase_auth/firebase_auth.dart';

String mapearErroAutenticacao(FirebaseAuthException excecao) {
  switch (excecao.code) {
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado. Tente entrar ou recuperar sua senha.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'weak-password':
      return 'A senha deve ter no mínimo 8 caracteres.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'E-mail ou senha incorretos.';
    case 'account-exists-with-different-credential':
      return 'Este e-mail já tem uma conta. Entre com seu e-mail e senha.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    case 'network-request-failed':
      return 'Falha de conexão. Verifique sua internet e tente novamente.';
    default:
      return 'Não foi possível concluir a operação. Tente novamente.';
  }
}
