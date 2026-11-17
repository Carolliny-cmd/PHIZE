import 'package:phize/features/comunidade/domain/compartilhador_texto.dart';
import 'package:phize/features/comunidade/domain/feed_repository.dart';
import 'package:phize/features/comunidade/domain/moderacao_repository.dart';
import 'package:phize/features/comunidade/domain/motivo_denuncia.dart';
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
  int denuncias = 0,
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
  denuncias: denuncias,
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
    this.falhaAoDenunciar = false,
    Map<String, MotivoDenuncia>? denunciados,
  }) : reportes = reportes ?? [reporteDeTeste()],
       curtidos = curtidos ?? {},
       denunciados = denunciados ?? {};

  List<ReporteComunidade> reportes;
  bool falhaAoListar;
  final bool falhaAoCurtir;
  final Set<String> curtidos;
  final bool falhaAoDenunciar;
  final Map<String, MotivoDenuncia> denunciados;
  final List<OrdemFeed> ordensPedidas = [];

  /// Hashes de links validados pela equipe (`ameacas`).
  Set<String> ameacas = {};

  /// Hash de link de cada reporte de link, para a pesquisa.
  Map<String, String> hashes = {};
  final List<List<String>> palavrasPesquisadas = [];

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

  @override
  Future<ResultadoPesquisaLink> pesquisarLink(String hash) async {
    if (falhaAoListar) throw Exception('sem rede');
    final reporte = reportes
        .where((r) => hashes[r.id] == hash || r.id == hash)
        .firstOrNull;
    return ResultadoPesquisaLink(
      reporte: reporte?.status == StatusReporte.oculto ? null : reporte,
      validadoPelaEquipe: ameacas.contains(hash),
    );
  }

  @override
  Future<List<ReporteComunidade>> pesquisarPalavras(
    List<String> palavras,
  ) async {
    if (falhaAoListar) throw Exception('sem rede');
    palavrasPesquisadas.add(palavras);
    return [
      for (final r in reportes)
        if (r.status != StatusReporte.oculto &&
            palavras.any(
              (p) =>
                  '${r.titulo} ${r.categoria.nome}'.toLowerCase().contains(p),
            ))
          r,
    ];
  }

  @override
  Future<bool> jaDenunciou(String reporteId) async =>
      denunciados.containsKey(reporteId);

  @override
  Future<void> denunciar(String reporteId, MotivoDenuncia motivo) async {
    if (falhaAoDenunciar || denunciados.containsKey(reporteId)) {
      throw Exception('recusado');
    }
    denunciados[reporteId] = motivo;
  }
}

class FakeModeracaoRepository implements ModeracaoRepository {
  FakeModeracaoRepository({
    this.moderador = true,
    List<ReporteComunidade>? reportes,
    Map<MotivoDenuncia, int>? motivos,
  }) : reportes = reportes ?? [],
       motivos = motivos ?? {};

  final bool moderador;
  List<ReporteComunidade> reportes;
  final Map<MotivoDenuncia, int> motivos;
  final List<(String, StatusReporte)> mudancas = [];
  final List<String> excluidos = [];

  @override
  Future<bool> ehModerador() async => moderador;

  @override
  Future<List<ReporteComunidade>> listar(StatusReporte status) async => [
    for (final r in reportes)
      if (r.status == status) r,
  ];

  @override
  Future<Map<MotivoDenuncia, int>> motivosDasDenuncias(
    String reporteId,
  ) async => motivos;

  @override
  Future<void> mudarStatus(
    ReporteComunidade reporte,
    StatusReporte status,
  ) async {
    final reporteId = reporte.id;
    mudancas.add((reporteId, status));
    reportes = [
      for (final r in reportes)
        r.id == reporteId
            ? ReporteComunidade(
                id: r.id,
                tipo: r.tipo,
                titulo: r.titulo,
                relato: r.relato,
                categoria: r.categoria,
                curtidas: r.curtidas,
                denuncias: r.denuncias,
                incidencias: r.incidencias,
                status: status,
                criadoEm: r.criadoEm,
              )
            : r,
    ];
  }

  @override
  Future<void> excluir(String reporteId) async {
    excluidos.add(reporteId);
    reportes = [
      for (final r in reportes)
        if (r.id != reporteId) r,
    ];
  }
}

class FakeCompartilhadorTexto implements CompartilhadorTexto {
  final List<String> enviados = [];

  @override
  Future<void> compartilhar(String texto) async => enviados.add(texto);
}
