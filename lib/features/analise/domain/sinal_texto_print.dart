/// Os 8 sinais do grupo Texto/Print (RF07).
///
/// Identificados pelo modelo de linguagem no conteúdo analisado; os pesos
/// atribuídos a cada um constam exclusivamente de `docs/score-calibracao.md`
/// (ScoreConfig.pesosTextoPrint).
enum SinalTextoPrint {
  correspondenciaPadraoCatalogado,
  pedidoFinanceiro,
  alegacaoTrocaContato,
  solicitacaoDadosPessoais,
  ameaca,
  linkSuspeito,
  ofertaIncompativelMercado,
  inducaoUrgencia,
}

extension SinalTextoPrintTitulo on SinalTextoPrint {
  /// Nome do sinal em linguagem não técnica (RF07, RNF04), usado na tela de
  /// resultado e no tutorial da análise de print.
  String get titulo => switch (this) {
    SinalTextoPrint.correspondenciaPadraoCatalogado =>
      'Semelhança com golpe já catalogado',
    SinalTextoPrint.pedidoFinanceiro => 'Pedido de dinheiro ou pagamento',
    SinalTextoPrint.alegacaoTrocaContato =>
      'Alegação de troca de número ou de contato',
    SinalTextoPrint.solicitacaoDadosPessoais => 'Pedido de dados pessoais',
    SinalTextoPrint.ameaca => 'Ameaça ou intimidação',
    SinalTextoPrint.linkSuspeito => 'Link suspeito',
    SinalTextoPrint.ofertaIncompativelMercado =>
      'Oferta boa demais para ser verdade',
    SinalTextoPrint.inducaoUrgencia => 'Pressão para agir com urgência',
  };
}
