import 'package:phize/features/analise/domain/tutorial_repository.dart';

class FakeTutorialRepository implements TutorialRepository {
  FakeTutorialRepository({Set<TipoTutorial>? vistos, this.falhaAoLer = false})
    : vistos = vistos ?? {...TipoTutorial.values};

  /// Por padrão, todos já vistos: os testes de fluxo não param no tutorial.
  final Set<TipoTutorial> vistos;
  final bool falhaAoLer;

  @override
  Future<bool> visto(TipoTutorial tipo) async {
    if (falhaAoLer) throw StateError('falha simulada');
    return vistos.contains(tipo);
  }

  @override
  Future<void> marcarVisto(TipoTutorial tipo) async => vistos.add(tipo);
}
