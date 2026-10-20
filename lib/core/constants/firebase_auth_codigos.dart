/// Códigos de erro do Firebase Auth (`FirebaseAuthException.code`) que o app
/// trata de forma específica, num único ponto para que clientes de trilhas
/// diferentes não dependam um do outro.
class FirebaseAuthCodigos {
  FirebaseAuthCodigos._();

  /// Falha de rede (sem conexão, servidor inalcançável ou tempo esgotado na
  /// renovação do token).
  static const String falhaRede = 'network-request-failed';
}
