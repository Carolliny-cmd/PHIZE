import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/features/analise/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/analise/presentation/pages/detalhe_historico_page.dart';

import '../../../support/fake_historico_repository.dart';

AnaliseRisco _analise({
  int score = 85,
  FaixaRisco faixa = FaixaRisco.alto,
  CategoriaAmeaca? categoria = CategoriaAmeaca.falsoContato,
  TipoEntrada tipo = TipoEntrada.imagem,
}) => AnaliseRisco(
  id: 'a1',
  score: score,
  faixa: faixa,
  categoria: categoria,
  explicacao: 'Golpistas fingem ser parentes.',
  tipoEntrada: tipo,
  data: DateTime(2026, 11, 3),
);

Future<void> _abrir(WidgetTester tester, FakeHistoricoRepository repo) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, historicoRepository: repo),
      initialRoute: AppRoutes.historico,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista as análises na ordem do repositório, com rótulo, score, '
      'tipo, data e o aviso permanente', (tester) async {
    await _abrir(
      tester,
      FakeHistoricoRepository(
        analises: [
          _analise(),
          _analise(
            score: 0,
            faixa: FaixaRisco.medio,
            categoria: null,
            tipo: TipoEntrada.link,
          ),
        ],
      ),
    );

    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
    expect(find.text('85'), findsOneWidget);
    expect(find.text('Print · 03/11/2026'), findsOneWidget);
    // Score baixo com faixa elevada: vale a faixa gravada, nunca o verde.
    expect(find.text(RotulosRisco.medioRisco), findsOneWidget);
    expect(find.text(RotulosRisco.baixoRisco), findsNothing);
    expect(find.text('Link · 03/11/2026'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('historico_aviso_permanente')),
      100,
    );
    expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
  });

  testWidgets('tocar em um registro abre o detalhe com a explicação e os '
      'avisos', (tester) async {
    await _abrir(tester, FakeHistoricoRepository(analises: [_analise()]));

    await tester.tap(find.text(RotulosRisco.altoRisco));
    await tester.pumpAndSettle();

    expect(find.text('Score de Risco: 85/100'), findsOneWidget);
    expect(find.text('Falso contato'), findsOneWidget);
    expect(find.text('Golpistas fingem ser parentes.'), findsOneWidget);
    expect(find.text('Print analisado em 03/11/2026'), findsOneWidget);
    expect(
      find.text(DetalheHistoricoPage.avisoZeroPersistencia),
      findsOneWidget,
    );
    expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
    expect(find.text(RotulosRisco.avisoFalibilidadeReputacao), findsNothing);
  });

  test('a orientação por faixa nunca afirma ausência de risco', () {
    for (final faixa in FaixaRisco.values) {
      expect(faixa.oQueFazer.toLowerCase(), isNot(contains('seguro')));
      expect(faixa.oQueFazer.toLowerCase(), isNot(contains('sem risco')));
    }
  });

  testWidgets('detalhe mostra o que fazer conforme a faixa gravada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetalheHistoricoPage(
          analise: _analise(score: 0, faixa: FaixaRisco.medio),
        ),
      ),
    );

    expect(find.text(RotulosRisco.oQueFazerMedioRisco), findsOneWidget);
  });

  testWidgets('detalhe de link: sem categoria e com o aviso do Safe Browsing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DetalheHistoricoPage(
          analise: _analise(categoria: null, tipo: TipoEntrada.link),
        ),
      ),
    );

    expect(find.text('Tipo de abordagem'), findsNothing);
    expect(find.text('Link analisado em 03/11/2026'), findsOneWidget);
    expect(find.text(RotulosRisco.avisoFalibilidadeReputacao), findsOneWidget);
  });

  testWidgets('histórico vazio orienta a primeira análise', (tester) async {
    await _abrir(tester, FakeHistoricoRepository());

    expect(find.textContaining('ainda não fez nenhuma'), findsOneWidget);
    await tester.tap(find.text('Fazer minha primeira análise'));
    await tester.pumpAndSettle();
    expect(find.text('Recebeu algo estranho?'), findsOneWidget);
  });

  testWidgets('falha ao carregar oferece nova tentativa', (tester) async {
    final repo = FakeHistoricoRepository(
      analises: [_analise()],
      falhaAoListar: true,
    );
    await _abrir(tester, repo);

    expect(find.textContaining('Não foi possível carregar'), findsOneWidget);
    repo.falhaAoListar = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(repo.leituras, 2);
    expect(find.text(RotulosRisco.altoRisco), findsOneWidget);
  });
}
