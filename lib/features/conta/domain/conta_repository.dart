/// Perfil (RF14) e direitos do titular (RF12 / UC12) sobre a conta
/// autenticada.
abstract class ContaRepository {
  /// Perfil gravado no Firestore, para a tela de perfil e a exportação.
  /// Lança em caso de falha.
  Future<PerfilConta> carregarPerfil();

  /// O que o Firebase Authentication já sabe da conta, sem rede.
  IdentidadeConta get identidade;

  /// Grava o nome de exibição já normalizado; `null` apaga o nome.
  /// Lança em caso de falha.
  Future<void> salvarNomeExibicao(String? nome);

  /// `false` para quem entra só com o Google e confirma a exclusão por ele.
  bool get exigeSenha;

  /// Confirma a identidade, pela [senha] ou pelo Google, e remove todos os documentos do usuário no Firestore
  /// e, por último, a credencial no Firebase Authentication.
  ///
  /// Pode ser chamado de novo depois de uma falha: o que já foi removido não
  /// atrapalha a nova tentativa.
  ///
  /// Lança [ExclusaoIncompletaException] se a remoção começou e não terminou.
  /// Qualquer outra falha, como `AuthException` para senha errada, significa
  /// que nada foi removido.
  Future<void> excluirConta({String? senha});

  /// `true` quando o usuário autenticado tem exclusão iniciada e não
  /// concluída neste aparelho (UC12, "Falha parcial na exclusão").
  Future<bool> exclusaoPendente();
}

class PerfilConta {
  const PerfilConta({
    required this.uid,
    required this.email,
    required this.criadaEm,
    this.nomeExibicao,
  });

  final String uid;
  final String? email;
  final DateTime? criadaEm;

  /// Opcional (RF14). Único dado pessoal acrescentado ao cadastro.
  final String? nomeExibicao;
}

/// Dados de identificação vindos do Firebase Authentication (RF14).
class IdentidadeConta {
  const IdentidadeConta({
    required this.email,
    required this.emailVerificado,
    required this.entraComSenha,
    required this.entraComGoogle,
  });

  final String? email;
  final bool emailVerificado;
  final bool entraComSenha;
  final bool entraComGoogle;
}

class ExclusaoIncompletaException implements Exception {
  const ExclusaoIncompletaException();
}
