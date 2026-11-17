import 'motivo_denuncia.dart';
import 'reporte_comunidade.dart';

/// Situação do pedido de inclusão de um reporte na base de conhecimento
/// (RNF05; arquitetura, 3.2 d). Quem responde é a Function.
enum EstadoNaBase { aguardando, incluido, recusado, falhou }

class SituacaoNaBase {
  const SituacaoNaBase(this.estado, [this.motivo]);

  final EstadoNaBase estado;

  /// Código do motivo de recusa ou falha, vindo da Function.
  final String? motivo;

  /// Texto mostrado à moderação.
  String get descricao => switch (estado) {
    EstadoNaBase.aguardando => 'Incluindo na base de conhecimento...',
    EstadoNaBase.incluido => 'Na base de conhecimento',
    EstadoNaBase.recusado || EstadoNaBase.falhou =>
      'Não entrou na base: ${switch (motivo) {
        'sem_frases' => 'o relato não tem frases que sirvam de padrão',
        'nao_aprovado' => 'o reporte não está aprovado',
        'reporte_de_link' => 'reporte de link não entra na base',
        'reporte_mudou' => 'o reporte mudou durante a inclusão',
        'limite_provedor' => 'limite do provedor de IA; tente mais tarde',
        _ => 'falha ao gerar a entrada; tente de novo',
      }}',
  };
}

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

  /// Aprova, oculta ou devolve a pendente. Aprovar um reporte de link
  /// registra a hash em `ameacas` como ameaça validada, que continua lá
  /// mesmo se o reporte for excluído depois (RF12); ocultar ou devolver a
  /// pendente retira a validação.
  Future<void> mudarStatus(ReporteComunidade reporte, StatusReporte status);

  /// Remoção definitiva do reporte (RF11).
  Future<void> excluir(String reporteId);

  /// Situação na base de cada reporte com pedido de inclusão, pelo id.
  Future<Map<String, SituacaoNaBase>> situacoesNaBase();

  /// "Aprovar e incluir na base": aprova (se preciso) e pede a inclusão na
  /// mesma gravação. É a curadoria do reporte (RNF05). Só relato e print.
  Future<void> incluirNaBase(ReporteComunidade reporte);

  /// Pede de novo depois de recusa ou falha.
  Future<void> pedirInclusaoDeNovo(String reporteId);
}
