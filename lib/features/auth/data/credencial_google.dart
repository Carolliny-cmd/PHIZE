import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_exception.dart';

const String mensagemFalhaGoogle =
    'Não foi possível entrar com o Google. Tente novamente.';

bool _inicializado = false;

/// Abre a escolha de conta do Google e devolve a credencial para o Firebase.
/// Devolve `null` se a pessoa desistir. Usada no login e na confirmação da
/// exclusão de conta, que exige autenticação recente.
Future<OAuthCredential?> obterCredencialGoogle() async {
  try {
    if (!_inicializado) {
      await GoogleSignIn.instance.initialize();
      _inicializado = true;
    }
    final conta = await GoogleSignIn.instance.authenticate();
    final idToken = conta.authentication.idToken;
    if (idToken == null) throw const AuthException(mensagemFalhaGoogle);
    return GoogleAuthProvider.credential(idToken: idToken);
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;
    throw const AuthException(mensagemFalhaGoogle);
  }
}
