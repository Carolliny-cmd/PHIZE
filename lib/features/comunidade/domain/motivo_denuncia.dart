/// Motivo de denúncia de um reporte da comunidade (RF11). O código é o
/// gravado no Firestore, na lista fechada das regras
/// (`docs/comunidade-dados.md`).
enum MotivoDenuncia {
  falso('falso', 'Informação falsa ou que não é golpe'),
  ofensivo('ofensivo', 'Conteúdo ofensivo'),
  duplicado('duplicado', 'Repete outro reporte'),
  acusaOrganizacaoLegitima(
    'acusa_organizacao_legitima',
    'Acusa uma empresa ou órgão legítimo',
  );

  const MotivoDenuncia(this.codigo, this.nome);

  final String codigo;
  final String nome;

  static MotivoDenuncia? doCodigo(Object? codigo) {
    for (final motivo in values) {
      if (motivo.codigo == codigo) return motivo;
    }
    return null;
  }
}
