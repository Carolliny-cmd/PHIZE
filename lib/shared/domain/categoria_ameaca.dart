/// Categoria da ameaça identificada na análise de print, persistida no
/// histórico junto com score, explicação, tipo de entrada e data (RNF07,
/// etapa 4; arquitetura, seção 5.4).
///
/// Fonte: `docs/categorias-ameaca.md` (versão 1.0, provisória, pendente de
/// validação pela equipe), que traz a justificativa de cada categoria.
/// Lista fechada, espelhada também em `CATEGORIAS_PERMITIDAS` da Function
/// (functions/src/analiseTexto.ts): o modelo só pode escolher uma destas, de
/// modo que nada além de um rótulo conhecido chega ao histórico.
enum CategoriaAmeaca {
  falsoContato('falso_contato'),
  falsaCentralOuInstituicao('falsa_central_ou_instituicao'),
  cobrancaOuBoletoFalso('cobranca_ou_boleto_falso'),
  ofertaOuPremioFalso('oferta_ou_premio_falso'),
  ameacaOuExtorsao('ameaca_ou_extorsao'),
  rouboDeDados('roubo_de_dados'),
  outroGolpe('outro_golpe'),
  semIndicios('sem_indicios');

  const CategoriaAmeaca(this.codigo);

  /// Valor trocado com a Function.
  final String codigo;

  /// Nome exibido ao usuário (`docs/categorias-ameaca.md`, coluna "Nome").
  String get nome => switch (this) {
    falsoContato => 'Falso contato',
    falsaCentralOuInstituicao => 'Falsa central ou instituição',
    cobrancaOuBoletoFalso => 'Cobrança ou boleto falso',
    ofertaOuPremioFalso => 'Oferta ou prêmio falso',
    ameacaOuExtorsao => 'Ameaça ou extorsão',
    rouboDeDados => 'Roubo de dados',
    outroGolpe => 'Outro golpe',
    semIndicios => 'Sem indícios',
  };

  static CategoriaAmeaca? doCodigo(Object? codigo) {
    for (final categoria in values) {
      if (categoria.codigo == codigo) return categoria;
    }
    return null;
  }
}
