import 'package:shared_preferences/shared_preferences.dart';

/// Marca, no aparelho, que a exclusão de uma conta começou e não terminou
/// (UC12, "Falha parcial na exclusão"). Guarda só o identificador do usuário
/// e sai junto com a conta.
///
/// Limitação: reinstalar o app ou entrar por outro aparelho perde a marca.
class PendenciaExclusao {
  static const String _chave = 'exclusao_conta_pendente_uid';

  Future<void> registrar(String uid) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chave, uid);
  }

  Future<void> limpar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chave);
  }

  Future<bool> existePara(String uid) async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString(_chave) == uid;
  }
}
