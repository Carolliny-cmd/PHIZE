import 'analise_risco.dart';

/// Histórico de análises do usuário autenticado (UC06).
abstract class HistoricoRepository {
  /// Grava o resultado de uma análise. Lança em caso de falha.
  Future<void> salvar(AnaliseRisco analise);

  /// Devolve as análises do usuário, da mais recente para a mais antiga.
  /// Lança em caso de falha.
  Future<List<AnaliseRisco>> listar();
}
