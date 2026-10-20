/// Fornece o ID token do Firebase Auth do usuário atual, ou `null` quando
/// não há sessão.
typedef ObterTokenId = Future<String?> Function();
