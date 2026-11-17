import 'reporte_comunidade.dart';

/// Leitura do feed e curtidas da comunidade (RF06, RF08). A implementação
/// real usa o Firestore (`docs/comunidade-dados.md`); os testes de tela usam
/// um dublê.
abstract class FeedRepository {
  /// Quantos reportes o feed carrega de cada vez.
  static const int limite = 50;

  /// Reportes visíveis (pendentes e aprovados; ocultos nunca), na ordem
  /// pedida. Lança exceção em falha de comunicação.
  Future<List<ReporteComunidade>> listar(OrdemFeed ordem);

  /// Se a conta atual já curtiu o reporte.
  Future<bool> jaCurtiu(String reporteId);

  /// Registra a curtida da conta atual: +1 no reporte junto com a marca da
  /// conta, uma vez só (RF06). Lança exceção se não for possível, inclusive
  /// se a conta já tinha curtido.
  Future<void> curtir(String reporteId);
}
