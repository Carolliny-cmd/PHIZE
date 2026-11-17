import '../../../shared/domain/categoria_ameaca.dart';
import 'novo_reporte.dart';

/// Situação de um reporte na moderação (RF11). Reporte oculto nunca chega
/// ao feed: as regras só o deixam ser lido pela moderação.
enum StatusReporte {
  pendente('pendente', 'Pendentes'),
  aprovado('aprovado', 'Aprovados'),
  oculto('oculto', 'Ocultos');

  const StatusReporte(this.codigo, this.nomeLista);

  final String codigo;

  /// Nome da lista na tela de moderação.
  final String nomeLista;

  static StatusReporte? doCodigo(Object? codigo) {
    for (final status in values) {
      if (status.codigo == codigo) return status;
    }
    return null;
  }
}

/// Ordem do feed (RF08): "Em alta" (mais curtidos) ou "Mais recentes".
enum OrdemFeed {
  emAlta('Em alta'),
  maisRecentes('Mais recentes');

  const OrdemFeed(this.nome);

  final String nome;
}

/// Reporte público como aparece no feed (RF08). Não tem autor, link nem
/// imagem: o documento não guarda nada disso (`docs/comunidade-dados.md`).
class ReporteComunidade {
  const ReporteComunidade({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.relato,
    required this.categoria,
    required this.curtidas,
    this.denuncias = 0,
    required this.incidencias,
    required this.status,
    required this.criadoEm,
  });

  final String id;
  final TipoReporte tipo;
  final String titulo;
  final String relato;
  final CategoriaAmeaca categoria;
  final int curtidas;

  /// Denúncias recebidas (RF11). Com 3, o reporte pendente é ocultado.
  final int denuncias;

  /// Quantas contas relataram ter recebido o golpe (UC05; o autor conta 1).
  final int incidencias;
  final StatusReporte status;
  final DateTime criadoEm;

  /// Nome exibido no lugar do autor (decisão da equipe de 2026-11-16).
  static const String autorAnonimo = 'Usuário do Phize';

  ReporteComunidade comMaisUmaCurtida() => ReporteComunidade(
    id: id,
    tipo: tipo,
    titulo: titulo,
    relato: relato,
    categoria: categoria,
    curtidas: curtidas + 1,
    denuncias: denuncias,
    incidencias: incidencias,
    status: status,
    criadoEm: criadoEm,
  );
}
