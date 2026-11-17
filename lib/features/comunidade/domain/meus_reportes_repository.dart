import 'motivo_denuncia.dart';
import 'preparacao_reporte.dart';
import 'reporte_comunidade.dart';

/// Um reporte publicado pela conta (RF16). [reporte] é `null` quando a
/// moderação já o excluiu: sobra só a autoria, que a pessoa pode apagar.
class MeuReporte {
  const MeuReporte({required this.id, required this.publicadoEm, this.reporte});

  final String id;
  final DateTime publicadoEm;
  final ReporteComunidade? reporte;
}

/// Tudo o que a conta deixou na comunidade (RF12): os próprios reportes e as
/// marcas de curtida, denúncia e "também recebi" em reportes de outras
/// pessoas.
class ParticipacaoComunidade {
  const ParticipacaoComunidade({
    required this.reportes,
    required this.curtidas,
    required this.denuncias,
    required this.incidencias,
  });

  static const vazia = ParticipacaoComunidade(
    reportes: [],
    curtidas: {},
    denuncias: {},
    incidencias: {},
  );

  final List<MeuReporte> reportes;

  /// Identificador do reporte curtido e a data.
  final Map<String, DateTime> curtidas;

  /// Identificador do reporte denunciado e o motivo.
  final Map<String, MotivoDenuncia?> denuncias;

  /// Identificador do reporte em que a conta disse "também recebi" e a data.
  final Map<String, DateTime> incidencias;
}

/// "Meus reportes" (RF16) e a participação da conta para a exportação
/// (RF12). Só o autor edita ou exclui: quem garante são as regras do
/// Firestore.
abstract class MeusReportesRepository {
  /// Reportes da conta, mais novos primeiro.
  Future<List<MeuReporte>> listar();

  /// Grava título e relato já preparados por `prepararEdicao`.
  Future<void> editar(String reporteId, EdicaoPronta edicao);

  /// Exclui o reporte e a autoria juntos (RF16, UC10). A hash de link já
  /// validado pela equipe continua em `ameacas`, sem autor (RF12).
  Future<void> excluir(String reporteId);

  /// Apaga a autoria de um reporte que a moderação já excluiu.
  Future<void> esquecer(String reporteId);

  /// Para a exportação de dados (RF12).
  Future<ParticipacaoComunidade> participacao();
}
