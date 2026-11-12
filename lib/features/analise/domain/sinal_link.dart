/// Os sinais do grupo Link (UC03).
///
/// Derivados da verificação de URL (Safe Browsing, typosquatting, RDAP); os
/// pesos atribuídos a cada um constam exclusivamente de
/// `docs/score-calibracao.md` (ScoreConfig.pesosLink).
enum SinalLink {
  listadoSafeBrowsing,
  typosquatting,
  dominioRecemCriado,
}

extension SinalLinkTitulo on SinalLink {
  /// Nome do sinal em linguagem não técnica (RF07, RNF04), usado na
  /// explicação de como o risco é calculado (RF14).
  String get titulo => switch (this) {
    SinalLink.listadoSafeBrowsing =>
      'Endereço na lista de sites perigosos do Google',
    SinalLink.typosquatting =>
      'Endereço parecido com o de uma empresa conhecida',
    SinalLink.dominioRecemCriado => 'Site criado há pouco tempo',
  };
}
