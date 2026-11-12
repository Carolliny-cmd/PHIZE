/// Nome de exibição do perfil (RF14): opcional, sem validação de nome real.
library;

/// Limite do RF14, também conferido pelas regras do Firestore.
const int limiteNomeExibicao = 40;

/// Tira espaços das pontas e repetidos no meio. Vazio vira `null`, que
/// significa "sem nome".
String? normalizarNomeExibicao(String texto) {
  final limpo = texto.trim().replaceAll(RegExp(r'\s+'), ' ');
  return limpo.isEmpty ? null : limpo;
}

/// Mensagem de erro para exibição, ou `null` se o nome pode ser gravado.
String? validarNomeExibicao(String texto) {
  final nome = normalizarNomeExibicao(texto);
  if (nome == null) return null;
  if (nome.length > limiteNomeExibicao) {
    return 'Use até $limiteNomeExibicao letras.';
  }
  return null;
}
