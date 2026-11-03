/// Entrega ao usuário um arquivo gerado pelo app.
abstract class CompartilhadorArquivo {
  /// Lança em caso de falha. Desistir do compartilhamento não é falha.
  Future<void> compartilhar({
    required String nomeArquivo,
    required String conteudo,
  });
}
