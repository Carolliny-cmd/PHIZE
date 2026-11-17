import 'motivo_denuncia.dart';
import 'reporte_comunidade.dart';

/// Moderação da comunidade (RF11). Só contas da lista `moderadores`, que a
/// equipe mantém pelo console, conseguem usar: as regras do Firestore
/// recusam o resto, e esta porta não é barreira de segurança.
abstract class ModeracaoRepository {
  /// Se a conta atual está na lista de moderação. Em falha, `false`.
  Future<bool> ehModerador();

  /// Reportes com o [status] pedido, mais novos primeiro (inclui ocultos).
  Future<List<ReporteComunidade>> listar(StatusReporte status);

  /// Quantas denúncias o reporte recebeu por motivo.
  Future<Map<MotivoDenuncia, int>> motivosDasDenuncias(String reporteId);

  /// Aprova, oculta ou devolve a pendente.
  Future<void> mudarStatus(String reporteId, StatusReporte status);

  /// Remoção definitiva do reporte (RF11).
  Future<void> excluir(String reporteId);
}
