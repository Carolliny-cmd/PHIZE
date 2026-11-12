import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/tutorial_repository.dart';

/// Guarda no aparelho a versão de cada tutorial já vista por usuário (RF13).
/// Reinstalar o app, ou entrar em outro aparelho, mostra o tutorial de novo.
class TutorialRepositoryLocal implements TutorialRepository {
  TutorialRepositoryLocal({String? Function()? uidAtual})
    : _uidAtual = uidAtual ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final String? Function() _uidAtual;

  static String chavePara(String uid, TipoTutorial tipo) =>
      'tutorial_${tipo.name}_$uid';

  /// Remove as marcas de [uid], na exclusão da conta.
  static Future<void> removerDe(String uid) async {
    final preferencias = await SharedPreferences.getInstance();
    for (final tipo in TipoTutorial.values) {
      await preferencias.remove(chavePara(uid, tipo));
    }
  }

  String _chave(TipoTutorial tipo) {
    final uid = _uidAtual();
    if (uid == null) throw StateError('Sem usuário autenticado.');
    return chavePara(uid, tipo);
  }

  @override
  Future<bool> visto(TipoTutorial tipo) async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getInt(_chave(tipo)) == versaoTutorial[tipo];
  }

  @override
  Future<void> marcarVisto(TipoTutorial tipo) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setInt(_chave(tipo), versaoTutorial[tipo]!);
  }
}
