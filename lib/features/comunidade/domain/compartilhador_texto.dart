/// Abre o menu de compartilhamento do aparelho com um texto (RF09).
abstract class CompartilhadorTexto {
  /// Lança em caso de falha. Desistir do compartilhamento não é falha.
  Future<void> compartilhar(String texto);
}
