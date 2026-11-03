import 'dart:async';

import '../domain/auth_exception.dart';

/// Tempo máximo de espera pela gravação do documento `users/{uid}` (UC01,
/// passo 7). O SDK do Firestore tenta de novo sem fim quando o servidor não
/// responde, e sem este limite a tela de cadastro ficaria carregando para
/// sempre.
const Duration limiteInicializacaoPerfil = Duration(seconds: 15);

const String mensagemFalhaInicializacaoPerfil =
    'Não foi possível concluir o cadastro. Verifique sua conexão e tente '
    'novamente.';

/// Executa [gravarPerfil] com limite de tempo. Em caso de falha ou de tempo
/// esgotado, chama [desfazerConta] para remover a credencial recém-criada no
/// Firebase Auth, permitindo que o usuário repita o cadastro com o mesmo
/// e-mail, e lança [AuthException].
///
/// A falha de [desfazerConta] é ignorada: a conta continua existindo sem
/// documento, e o usuário ainda consegue entrar pelo login.
Future<void> inicializarPerfilOuDesfazer({
  required Future<void> Function() gravarPerfil,
  required Future<void> Function() desfazerConta,
  Duration limite = limiteInicializacaoPerfil,
}) async {
  try {
    await gravarPerfil().timeout(limite);
  } catch (_) {
    try {
      await desfazerConta().timeout(limite);
    } catch (_) {
      // Sem conexão a remoção também falha; a mensagem ao usuário é a mesma.
    }
    throw const AuthException(mensagemFalhaInicializacaoPerfil);
  }
}
