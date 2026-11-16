import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/consentimento_repository_local.dart';
import 'package:phize/features/analise/domain/consentimento_repository.dart';
import 'package:phize/features/analise/presentation/pages/consentimento_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_consentimento_repository.dart';

void main() {
  group('ConsentimentoRepositoryLocal', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('vale por usuário', () async {
      var uid = 'a';
      final repositorio = ConsentimentoRepositoryLocal(uidAtual: () => uid);

      await repositorio.aceitar();
      expect(await repositorio.aceito(), isTrue);

      uid = 'b';
      expect(await repositorio.aceito(), isFalse);
    });

    test('pode ser revogado', () async {
      final repositorio = ConsentimentoRepositoryLocal(uidAtual: () => 'a');

      await repositorio.aceitar();
      await repositorio.revogar();

      expect(await repositorio.aceito(), isFalse);
    });

    test('aceite de versão anterior não vale', () async {
      SharedPreferences.setMockInitialValues({
        ConsentimentoRepositoryLocal.chavePara('a'):
            versaoConsentimentoAnalise - 1,
      });
      final repositorio = ConsentimentoRepositoryLocal(uidAtual: () => 'a');

      expect(await repositorio.aceito(), isFalse);
    });
  });

  group('confirmarConsentimento', () {
    late bool? resultado;

    Future<void> abrir(
      WidgetTester tester,
      ConsentimentoRepository repositorio,
    ) async {
      resultado = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado = await confirmarConsentimento(context, repositorio);
              },
              child: const Text('analisar'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('analisar'));
      await tester.pumpAndSettle();
    }

    testWidgets('quem já aceitou não vê o aviso', (tester) async {
      await abrir(tester, FakeConsentimentoRepository());

      expect(find.byType(ConsentimentoPage), findsNothing);
      expect(resultado, isTrue);
    });

    testWidgets('o aviso declara os limites do mascaramento', (tester) async {
      await abrir(tester, FakeConsentimentoRepository(aceitou: false));

      expect(find.textContaining('Nomes de pessoas'), findsOneWidget);
      expect(find.textContaining('Gemini'), findsWidgets);
    });

    testWidgets('o aviso pede só conversas de teste (RNF07, escopo acadêmico)', (
      tester,
    ) async {
      await abrir(tester, FakeConsentimentoRepository(aceitou: false));

      final aviso = find.byKey(const Key('consentimento_aviso_teste'));
      await tester.ensureVisible(aviso);
      expect(aviso, findsOneWidget);
      expect(
        find.descendant(
          of: aviso,
          matching: find.textContaining('versão gratuita do Gemini'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: aviso,
          matching: find.textContaining('não analise conversas reais'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('aceitar libera e fica registrado', (tester) async {
      final repositorio = FakeConsentimentoRepository(aceitou: false);
      await abrir(tester, repositorio);

      await tester.ensureVisible(
        find.byKey(const Key('consentimento_aceitar')),
      );
      await tester.tap(find.byKey(const Key('consentimento_aceitar')));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
      expect(repositorio.aceitou, isTrue);
    });

    testWidgets('recusar não libera', (tester) async {
      final repositorio = FakeConsentimentoRepository(aceitou: false);
      await abrir(tester, repositorio);

      await tester.ensureVisible(
        find.byKey(const Key('consentimento_recusar')),
      );
      await tester.tap(find.byKey(const Key('consentimento_recusar')));
      await tester.pumpAndSettle();

      expect(resultado, isFalse);
    });

    testWidgets('em celular pequeno, os botões aparecem sem rolar a tela', (
      tester,
    ) async {
      // Achado 7 do ensaio de 2026-11-16: o botão ficava abaixo da dobra.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrir(tester, FakeConsentimentoRepository(aceitou: false));

      for (final chave in ['consentimento_aceitar', 'consentimento_recusar']) {
        final botao = tester.getRect(find.byKey(Key(chave)));
        expect(botao.top, greaterThanOrEqualTo(0));
        expect(botao.bottom, lessThanOrEqualTo(640));
      }
      // O texto continua rolando acima dos botões.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('voltar sem responder não libera', (tester) async {
      await abrir(tester, FakeConsentimentoRepository(aceitou: false));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(resultado, isFalse);
    });
  });
}
