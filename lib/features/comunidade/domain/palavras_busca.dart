/// Palavras de pesquisa da comunidade (RF15), extraídas do mesmo jeito no
/// reporte e na busca: minúsculas, sem acento, com 3 letras ou mais, sem os
/// marcadores do mascaramento (`[CPF]`, `[LINK]`...), sem repetição e no
/// máximo [maximoPalavras], o limite das regras do Firestore.
library;

const int maximoPalavras = 20;

const Map<String, String> _semAcento = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'ê': 'e',
  'è': 'e',
  'ë': 'e',
  'í': 'i',
  'î': 'i',
  'ì': 'i',
  'ï': 'i',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ò': 'o',
  'ö': 'o',
  'ú': 'u',
  'û': 'u',
  'ù': 'u',
  'ü': 'u',
  'ç': 'c',
};

String normalizarParaBusca(String texto) {
  final minusculo = texto.toLowerCase();
  final buffer = StringBuffer();
  for (final caractere in minusculo.split('')) {
    buffer.write(_semAcento[caractere] ?? caractere);
  }
  return buffer.toString();
}

List<String> palavrasDeBusca(Iterable<String> textos) {
  final palavras = <String>{};
  for (final texto in textos) {
    final semMarcadores = texto.replaceAll(RegExp(r'\[[A-Z_]+\]'), ' ');
    for (final palavra in normalizarParaBusca(
      semMarcadores,
    ).split(RegExp(r'[^a-z0-9]+'))) {
      if (palavra.length >= 3) palavras.add(palavra);
      if (palavras.length == maximoPalavras) return palavras.toList();
    }
  }
  return palavras.toList();
}
