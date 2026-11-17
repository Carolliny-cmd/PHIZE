import 'package:phize/features/comunidade/domain/compartilhador_texto.dart';
import 'package:phize/features/comunidade/domain/feed_repository.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

/// Reporte fictício para os testes da comunidade.
ReporteComunidade reporteDeTeste({
  String id = 'r1',
  TipoReporte tipo = TipoReporte.relato,
  String titulo = 'Falso parente pedindo Pix',
  String relato = 'Mensagem de número novo dizendo que trocou de celular.',
  CategoriaAmeaca categoria = CategoriaAmeaca.falsoContato,
  int curtidas = 3,
  int incidencias = 2,
  StatusReporte status = StatusReporte.pendente,
  DateTime? criadoEm,
}) => ReporteComunidade(
  id: id,
  tipo: tipo,
  titulo: titulo,
  relato: relato,
  categoria: categoria,
  curtidas: curtidas,
  incidencias: incidencias,
  status: status,
  criadoEm: criadoEm ?? DateTime(2026, 11, 16),
);

class FakeFeedRepository implements FeedRepository {
  FakeFeedRepository({
    List<ReporteComunidade>? reportes,
    this.falhaAoListar = false,
    this.falhaAoCurtir = false,
    Set<String>? curtidos,
  }) : reportes = reportes ?? [reporteDeTeste()],
       curtidos = curtidos ?? {};

  List<ReporteComunidade> reportes;
  bool falhaAoListar;
  final bool falhaAoCurtir;
  final Set<String> curtidos;
  final List<OrdemFeed> ordensPedidas = [];

  @override
  Future<List<ReporteComunidade>> listar(OrdemFeed ordem) async {
    ordensPedidas.add(ordem);
    if (falhaAoListar) throw Exception('sem rede');
    final copia = [...reportes];
    switch (ordem) {
      case OrdemFeed.emAlta:
        copia.sort((a, b) => b.curtidas.compareTo(a.curtidas));
      case OrdemFeed.maisRecentes:
        copia.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    }
    return copia;
  }

  @override
  Future<bool> jaCurtiu(String reporteId) async => curtidos.contains(reporteId);

  @override
  Future<void> curtir(String reporteId) async {
    if (falhaAoCurtir || curtidos.contains(reporteId)) {
      throw Exception('recusado');
    }
    curtidos.add(reporteId);
    reportes = [
      for (final r in reportes) r.id == reporteId ? r.comMaisUmaCurtida() : r,
    ];
  }
}

class FakeCompartilhadorTexto implements CompartilhadorTexto {
  final List<String> enviados = [];

  @override
  Future<void> compartilhar(String texto) async => enviados.add(texto);
}
