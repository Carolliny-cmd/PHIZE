/// Direitos do titular sobre a conta autenticada (RF12 / UC12).
abstract class ContaRepository {
  /// Perfil gravado no cadastro, para a exportação. Lança em caso de falha.
  Future<PerfilConta> carregarPerfil();

  /// Confirma a senha e remove todos os documentos do usuário no Firestore
  /// e, por último, a credencial no Firebase Authentication.
  ///
  /// Pode ser chamado de novo depois de uma falha: o que já foi removido não
  /// atrapalha a nova tentativa.
  ///
  /// Lança [ExclusaoIncompletaException] se a remoção começou e não terminou.
  /// Qualquer outra falha, como `AuthException` para senha errada, significa
  /// que nada foi removido.
  Future<void> excluirConta({required String senha});

  /// `true` quando o usuário autenticado tem exclusão iniciada e não
  /// concluída neste aparelho (UC12, "Falha parcial na exclusão").
  Future<bool> exclusaoPendente();
}

class PerfilConta {
  const PerfilConta({
    required this.uid,
    required this.email,
    required this.criadaEm,
  });

  final String uid;
  final String? email;
  final DateTime? criadaEm;
}

class ExclusaoIncompletaException implements Exception {
  const ExclusaoIncompletaException();
}
