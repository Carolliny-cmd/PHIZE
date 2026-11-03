import 'analise_risco.dart';

/// Histórico de análises do usuário autenticado (UC06).
abstract class HistoricoRepository {
  /// Grava o resultado de uma análise. Lança em caso de falha.
  Future<void> salvar(AnaliseRisco analise);

  /// Devolve as análises do usuário, da mais recente para a mais antiga.
  /// Lança em caso de falha.
  ///
  /// Sem conexão, a consulta normal pode devolver só o que está no cache do
  /// aparelho. Com [somenteServidor], ela falha nesse caso: é o que a
  /// exportação precisa, para não entregar um arquivo incompleto como se
  /// fosse a íntegra dos dados (RF12).
  Future<List<AnaliseRisco>> listar({bool somenteServidor = false});
}
