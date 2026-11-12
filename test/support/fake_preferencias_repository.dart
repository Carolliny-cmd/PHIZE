import 'package:phize/features/conta/domain/preferencias_aparencia.dart';

class FakePreferenciasRepository implements PreferenciasRepository {
  FakePreferenciasRepository({
    this.gravadas = const PreferenciasAparencia(),
    this.falhaAoSalvar = false,
  });

  PreferenciasAparencia gravadas;
  bool falhaAoSalvar;
  int gravacoes = 0;

  @override
  Future<PreferenciasAparencia> ler() async => gravadas;

  @override
  Future<void> salvar(PreferenciasAparencia preferencias) async {
    if (falhaAoSalvar) throw StateError('falha simulada');
    gravacoes++;
    gravadas = preferencias;
  }
}
