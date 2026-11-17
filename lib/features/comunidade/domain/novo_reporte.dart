import '../../../shared/domain/categoria_ameaca.dart';

/// Tipo de reporte da comunidade (RF05). O valor é o gravado no Firestore
/// (`docs/comunidade-dados.md`).
enum TipoReporte {
  link('link', 'Link'),
  relato('relato', 'Relato'),
  print('print', 'Print');

  const TipoReporte(this.codigo, this.nome);

  final String codigo;
  final String nome;
}

/// Reporte pronto para publicar: título e relato já mascarados e sem links,
/// link só como hash. Não tem autor nem imagem (RF05; arquitetura, 5.5).
class NovoReporte {
  const NovoReporte({
    required this.tipo,
    required this.titulo,
    required this.relato,
    required this.categoria,
    required this.palavras,
    this.hashLink,
  });

  final TipoReporte tipo;
  final String titulo;
  final String relato;
  final CategoriaAmeaca categoria;

  /// Palavras para a pesquisa (RF15), tiradas do título e da categoria.
  final List<String> palavras;

  /// SHA-256 do domínio normalizado; só em [TipoReporte.link].
  final String? hashLink;
}
