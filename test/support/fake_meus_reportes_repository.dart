import 'package:phize/features/comunidade/domain/meus_reportes_repository.dart';
import 'package:phize/features/comunidade/domain/preparacao_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';

/// Conteúdo fictício em todos os casos.
class FakeMeusReportesRepository implements MeusReportesRepository {
  FakeMeusReportesRepository({
    List<MeuReporte>? reportes,
    this.participacaoFixa,
    this.falhaAoSalvar = false,
  }) : reportes = reportes ?? [];

  List<MeuReporte> reportes;
  final ParticipacaoComunidade? participacaoFixa;
  final bool falhaAoSalvar;
  final List<(String, EdicaoPronta)> edicoes = [];
  final List<String> excluidos = [];
  final List<String> esquecidos = [];

  @override
  Future<List<MeuReporte>> listar() async => [...reportes];

  @override
  Future<void> editar(String reporteId, EdicaoPronta edicao) async {
    if (falhaAoSalvar) throw Exception('sem rede');
    edicoes.add((reporteId, edicao));
    reportes = [
      for (final meu in reportes)
        if (meu.id == reporteId && meu.reporte != null)
          MeuReporte(
            id: meu.id,
            publicadoEm: meu.publicadoEm,
            reporte: ReporteComunidade(
              id: meu.reporte!.id,
              tipo: meu.reporte!.tipo,
              titulo: edicao.titulo,
              relato: edicao.relato,
              categoria: meu.reporte!.categoria,
              curtidas: meu.reporte!.curtidas,
              denuncias: meu.reporte!.denuncias,
              incidencias: meu.reporte!.incidencias,
              status: meu.reporte!.status,
              criadoEm: meu.reporte!.criadoEm,
            ),
          )
        else
          meu,
    ];
  }

  @override
  Future<void> excluir(String reporteId) async {
    excluidos.add(reporteId);
    reportes = [
      for (final meu in reportes)
        if (meu.id != reporteId) meu,
    ];
  }

  @override
  Future<void> esquecer(String reporteId) async {
    esquecidos.add(reporteId);
    reportes = [
      for (final meu in reportes)
        if (meu.id != reporteId) meu,
    ];
  }

  @override
  Future<ParticipacaoComunidade> participacao() async =>
      participacaoFixa ??
      ParticipacaoComunidade(
        reportes: reportes,
        curtidas: const {},
        denuncias: const {},
        incidencias: const {},
      );
}
