import 'novo_reporte.dart';

/// O que aconteceu ao publicar um reporte (RF05, UC05).
enum ResultadoPublicacao {
  /// Reporte novo, com status pendente.
  publicado,

  /// O link já tinha sido reportado: contou como mais um caso (+1 incidência).
  incidenciaRegistrada,

  /// A própria conta já tinha reportado ou confirmado este link.
  jaRegistradoPorVoce,

  /// O link já foi reportado e está oculto, em revisão pela equipe (RF11).
  emRevisao,
}

/// Porta de gravação dos reportes. A implementação real grava no Firestore
/// (`docs/comunidade-dados.md`); os testes de tela usam um dublê.
abstract class ReporteRepository {
  /// Lança exceção em falha de comunicação. O reporte continua só em
  /// memória, na tela, para nova tentativa: nada vai para disco ou cache
  /// (UC05; RNF07, etapa 3).
  Future<ResultadoPublicacao> publicar(NovoReporte reporte);
}
