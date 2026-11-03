import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/features/analise/domain/historico_repository.dart';

class FakeHistoricoRepository implements HistoricoRepository {
  FakeHistoricoRepository({
    List<AnaliseRisco>? analises,
    this.falhaAoSalvar = false,
    this.falhaAoListar = false,
  }) : analises = analises ?? [];

  final List<AnaliseRisco> analises;
  bool falhaAoSalvar;
  bool falhaAoListar;
  int leituras = 0;

  @override
  Future<void> salvar(AnaliseRisco analise) async {
    if (falhaAoSalvar) throw StateError('falha simulada');
    analises.add(analise);
  }

  @override
  Future<List<AnaliseRisco>> listar() async {
    leituras++;
    if (falhaAoListar) throw StateError('falha simulada');
    return analises;
  }
}
