import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/analise/domain/sinal_link.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';
import 'package:phize/features/analise/domain/tutorial_repository.dart';
import 'package:phize/features/analise/presentation/pages/como_calcula_risco_page.dart';
import 'package:phize/features/analise/presentation/tutorial/tutorial_link.dart';
import 'package:phize/features/analise/presentation/tutorial/tutorial_print.dart';
import 'package:phize/features/conta/presentation/pages/perfil_page.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_consentimento_repository.dart';
import '../../../support/fake_conta_repository.dart';
import '../../../support/fake_historico_repository.dart';
import '../../../support/fake_tutorial_repository.dart';

final _termoProibido = RegExp(r'\bsegur[oa]s?\b', caseSensitive: false);

Future<void> _abrir(
  WidgetTester tester, {
  FakeTutorialRepository? tutorial,
  Future<String> Function()? lerVersao,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PerfilPage(
        contaRepository: FakeContaRepository(),
        historicoRepository: FakeHistoricoRepository(),
        compartilhador: FakeCompartilhador(),
        authRepository: FakeAuthRepository(),
        consentimentoRepository: FakeConsentimentoRepository(),
        tutorialRepository: tutorial ?? FakeTutorialRepository(),
        lerVersao: lerVersao ?? () async => '1.0.0 (1)',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = find.byKey(Key(chave));
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// Todo o texto exibido na tela, para conferir o que não pode aparecer.
String _textoDaTela(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');

void main() {
  group('Aprender (RF14)', () {
    for (final (tipo, chave, pagina) in [
      (TipoTutorial.link, 'perfil_tutorial_link', TutorialLinkPage),
      (TipoTutorial.print, 'perfil_tutorial_print', TutorialPrintPage),
    ]) {
      testWidgets('reabre o tutorial de ${tipo.name}, mesmo já visto', (
        tester,
      ) async {
        final tutorial = FakeTutorialRepository();
        await _abrir(tester, tutorial: tutorial);

        await _tocar(tester, chave);
        expect(find.byType(pagina), findsOneWidget);

        await tester.tap(find.byKey(const Key('tutorial_pular')));
        await tester.pumpAndSettle();
        expect(find.byType(pagina), findsNothing);
        expect(find.byType(PerfilPage), findsOneWidget);
        expect(tutorial.vistos, contains(tipo));
      });
    }

    testWidgets('"Como o Phize calcula o risco" abre a explicação', (
      tester,
    ) async {
      await _abrir(tester);
      await _tocar(tester, 'perfil_como_calcula');
      expect(find.byType(ComoCalculaRiscoPage), findsOneWidget);
    });
  });

  group('Como o Phize calcula o risco (RF14, RF07)', () {
    Future<void> abrirExplicacao(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ComoCalculaRiscoPage()));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra os sinais, as três faixas oficiais e o aviso', (
      tester,
    ) async {
      await abrirExplicacao(tester);

      for (final sinal in SinalTextoPrint.values) {
        expect(find.text(sinal.titulo), findsOneWidget);
      }
      for (final sinal in SinalLink.values) {
        expect(find.text(sinal.titulo), findsOneWidget);
      }
      for (final faixa in FaixaRisco.values) {
        expect(find.text(faixa.rotulo), findsOneWidget);
      }
      expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
    });

    testWidgets('não usa o termo "Seguro"', (tester) async {
      await abrirExplicacao(tester);
      expect(_termoProibido.hasMatch(_textoDaTela(tester)), isFalse);
    });

    testWidgets('não mostra pesos nem pontos de corte', (tester) async {
      await abrirExplicacao(tester);

      // Só os extremos da escala podem aparecer: qualquer outro número
      // seria peso ou ponto de corte, cuja fonte única é
      // docs/score-calibracao.md.
      final numeros = RegExp(r'\d+')
          .allMatches(_textoDaTela(tester))
          .map((m) => m.group(0))
          .toSet();
      expect(numeros, {'0', '100'});
    });
  });

  group('Sobre o Phize (RF14)', () {
    testWidgets('mostra a versão do app e o aviso permanente', (tester) async {
      await _abrir(tester, lerVersao: () async => '1.2.3 (45)');

      await tester.ensureVisible(find.byKey(const Key('perfil_versao')));
      expect(find.text('1.2.3 (45)'), findsOneWidget);
      expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
    });

    testWidgets('sem a versão, mostra "Não disponível"', (tester) async {
      await _abrir(tester, lerVersao: () async => throw StateError('sem'));

      expect(
        find.descendant(
          of: find.byKey(const Key('perfil_versao')),
          matching: find.text('Não disponível'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('o perfil inteiro não usa o termo "Seguro"', (tester) async {
      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _abrir(tester);
      expect(_termoProibido.hasMatch(_textoDaTela(tester)), isFalse);
    });
  });
}
