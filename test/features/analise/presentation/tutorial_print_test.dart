import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/theme/app_theme.dart';
import 'package:phize/features/analise/domain/analisador_print.dart';
import 'package:phize/features/analise/domain/exemplo_tutorial_print.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';
import 'package:phize/features/analise/presentation/tutorial/tutorial_print.dart';

final _termoProibido = RegExp(r'\bsegur[oa]s?\b', caseSensitive: false);

Future<void> _abrir(
  WidgetTester tester, {
  double escalaTexto = 1,
  bool semAnimacao = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, filho) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escalaTexto),
          disableAnimations: semAnimacao,
        ),
        child: filho!,
      ),
      home: const TutorialPrintPage(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _etapa(int n) => find.bySemanticsLabel(RegExp('Etapa $n de 4'));

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = find.byKey(Key(chave));
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _avancar(WidgetTester tester) =>
    _tocar(tester, 'tutorial_proximo');

void _celular(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  final principal = ExemploTutorialPrint.todos.first;
  final noCelular = find.byKey(const Key('tutorial_resultado_exemplo'));

  testWidgets('simulação: tirar o print, compartilhar, ver o que sai do '
      'celular e o resultado', (tester) async {
    await _abrir(tester);

    // Etapa 1: tirar o print.
    expect(_etapa(1), findsOneWidget);
    expect(find.byKey(const Key('tutorial_print_tirado')), findsNothing);
    await _tocar(tester, 'tutorial_tirar_print');
    expect(find.byKey(const Key('tutorial_print_tirado')), findsOneWidget);
    await _avancar(tester);

    // Etapa 2: tocar no Phize no menu de compartilhar leva adiante.
    expect(_etapa(2), findsOneWidget);
    await _tocar(tester, 'tutorial_compartilhar_phize');

    // Etapa 3: as etapas reais da análise e o texto já mascarado.
    expect(_etapa(3), findsOneWidget);
    for (final etapa in EtapaAnalisePrint.values) {
      expect(find.text(etapa.titulo), findsOneWidget);
    }
    final enviado = find.byKey(const Key('tutorial_texto_enviado'));
    expect(
      find.descendant(
        of: enviado,
        matching: find.textContaining('[TELEFONE]', findRichText: true),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: enviado,
        matching: find.textContaining('[CPF]', findRichText: true),
      ),
      findsOneWidget,
    );
    await _tocar(tester, 'tutorial_ver_resultado');

    // Etapa 4: o resultado do motor de score, com os sinais do exemplo.
    expect(_etapa(4), findsOneWidget);
    final resultado = principal.resultado;
    for (final texto in [
      resultado.rotulo,
      '${resultado.pontuacao}',
      for (final sinal in principal.sinaisEmOrdem) sinal.titulo,
    ]) {
      expect(
        find.descendant(of: noCelular, matching: find.text(texto)),
        findsOneWidget,
        reason: texto,
      );
    }
    expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
  });

  testWidgets('o texto que sai do celular não mostra os dados nem a '
      'resposta da pessoa', (tester) async {
    await _abrir(tester, semAnimacao: true);
    await _avancar(tester);
    await _avancar(tester);
    await tester.pump();

    final enviado = find.byKey(const Key('tutorial_texto_enviado'));
    expect(
      find.descendant(
        of: enviado,
        matching: find.textContaining('98765-4321', findRichText: true),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: enviado,
        matching: find.textContaining('123.456.789-09', findRichText: true),
      ),
      findsNothing,
    );
    for (final resposta in principal.respostas) {
      expect(
        find.descendant(
          of: enviado,
          matching: find.textContaining(resposta, findRichText: true),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('outros exemplos mostram o resultado do motor', (tester) async {
    await _abrir(tester);
    for (var i = 0; i < 3; i++) {
      await _avancar(tester);
    }

    for (final (i, exemplo) in ExemploTutorialPrint.todos.indexed) {
      await _tocar(tester, 'tutorial_exemplo_$i');
      final resultado = exemplo.resultado;
      expect(
        find.descendant(of: noCelular, matching: find.text(resultado.rotulo)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: noCelular,
          matching: find.text(resultado.faixa.oQueFazer),
        ),
        findsOneWidget,
      );
      if (exemplo.sinais.isEmpty) {
        expect(resultado.faixa, FaixaRisco.baixo);
      }
    }
  });

  testWidgets('nenhuma etapa usa o termo proibido "Seguro"', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'tutorial_tirar_print');
    expect(find.textContaining(_termoProibido), findsNothing);
    await _avancar(tester);
    expect(find.textContaining(_termoProibido), findsNothing);
    await _avancar(tester);
    expect(find.textContaining(_termoProibido), findsNothing);
    await _avancar(tester);
    for (var i = 0; i < ExemploTutorialPrint.todos.length; i++) {
      await _tocar(tester, 'tutorial_exemplo_$i');
      expect(find.textContaining(_termoProibido), findsNothing);
    }
  });

  testWidgets('letra muito grande em celular pequeno, sem estouro', (
    tester,
  ) async {
    _celular(tester);
    await _abrir(tester, escalaTexto: 1.6);

    await _tocar(tester, 'tutorial_tirar_print');
    await _avancar(tester);
    await _tocar(tester, 'tutorial_compartilhar_phize');
    await _tocar(tester, 'tutorial_ver_resultado');
    for (var i = 0; i < ExemploTutorialPrint.todos.length; i++) {
      await _tocar(tester, 'tutorial_exemplo_$i');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('com redução de movimento, a leitura conclui de uma vez', (
    tester,
  ) async {
    await _abrir(tester, semAnimacao: true);
    await tester.tap(find.byKey(const Key('tutorial_proximo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tutorial_proximo')));
    await tester.pump();
    await tester.pump();

    expect(_etapa(3), findsOneWidget);
    await _tocar(tester, 'tutorial_ver_resultado');
    expect(_etapa(4), findsOneWidget);
  });
}
