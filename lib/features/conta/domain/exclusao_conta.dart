import 'conta_repository.dart';

/// Ordem da exclusão de conta (RF12; UC12, passo 5).
///
/// Só a etapa de remoção pode deixar a conta pela metade. Uma falha antes
/// dela não apagou nada e chega a quem chamou como veio, sem bloquear a conta.
/// Uma falha durante a remoção mantém a pendência registrada e vira
/// [ExclusaoIncompletaException]. Uma falha depois de [removerCredencial] não
/// importa mais: a conta já não existe.
Future<void> executarExclusaoConta<T>({
  required Future<void> Function() confirmarSenha,
  required Future<T> Function() lerDocumentos,
  required Future<void> Function() registrarPendencia,
  required Future<void> Function(T documentos) removerDocumentos,
  required Future<void> Function() removerCredencial,
  required Future<void> Function() concluir,
}) async {
  await confirmarSenha();
  final documentos = await lerDocumentos();
  await registrarPendencia();
  try {
    await removerDocumentos(documentos);
    await removerCredencial();
  } catch (_) {
    throw const ExclusaoIncompletaException();
  }
  try {
    await concluir();
  } catch (_) {
    // A marca que sobrar é de uma conta que não existe mais.
  }
}
