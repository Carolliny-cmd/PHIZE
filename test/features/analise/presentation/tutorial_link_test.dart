import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/theme/app_theme.dart';
import 'package:phize/features/analise/data/tutorial_repository_local.dart';
import 'package:phize/features/analise/domain/analisador_link.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/consulta_idade_dominio.dart';
import 'package:phize/features/analise/domain/consulta_reputacao_dominio.dart';
import 'package:phize/features/analise/domain/exemplo_tutorial_link.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/rdap_client.dart';
import 'package:phize/features/analise/domain/reputacao_dominio_client.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/sinal_link.dart';
import 'package:phize/features/analise/domain/tutorial_repository.dart';
import 'package:phize/features/analise/presentation/pages/analisar_link_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_historico_repository.dart';
import '../../../support/fake_tutorial_repository.dart';

/// Nenhuma chamada de rede é aceita: o exemplo do tutorial não consulta nada.
class _RdapProibido implements RdapClient {
  int chamadas = 0;

  @override
  Future<Map<String, dynamic>> consultarDominio(String dominio) async {
    chamadas++;
    throw const RdapIndisponivelException('não deveria ser chamado');
  }
}

class _ReputacaoProibida implements ReputacaoDominioClient {
  int chamadas = 0;

  @override
  Future<Map<String, dynamic>> consultarUrl(String url) async {
    chamadas++;
    throw const ReputacaoIndisponivelException('não deveria ser chamado');
  }
}

final _termoProibido = RegExp(r'\bsegur[oa]s?\b', caseSensitive: false);

const _tituloTutorial = 'Copie o link, sem abrir';

class _Tela {
  _Tela({FakeTutorialRepository? tutorial})
    : tutorial = tutorial ?? FakeTutorialRepository(vistos: {});

  final FakeTutorialRepository tutorial;
  final historico = FakeHistoricoRepository();
  final rdap = _RdapProibido();
  final reputacao = _ReputacaoProibida();

  Future<void> abrir(
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
        home: AnalisarLinkPage(
          analisadorLink: AnalisadorLink(
            ConsultaIdadeDominio(rdap),
            ConsultaReputacaoDominio(reputacao),
          ),
          historicoRepository: historico,
          tutorialRepository: tutorial,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// Tamanho de um celular pequeno, para pegar estouro de layout.
void _celular(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Depois de rolar até um resultado, a próxima opção pode estar fora da tela.
Future<void> _escolherExemplo(WidgetTester tester, int i) async {
  final opcao = find.byKey(Key('tutorial_exemplo_$i'));
  await tester.ensureVisible(opcao);
  await tester.pumpAndSettle();
  await tester.tap(opcao);
  await tester.pumpAndSettle();
}

Finder _etapa(int n) => find.bySemanticsLabel(RegExp('Etapa $n de 4'));

Future<void> _tocar(
  WidgetTester tester,
  String chave, {
  bool longo = false,
}) async {
  final alvo = find.byKey(Key(chave));
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  if (longo) {
    await tester.longPress(alvo);
  } else {
    await tester.tap(alvo, warnIfMissed: false);
  }
  await tester.pumpAndSettle();
}

Future<void> _avancar(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tutorial_proximo')));
  await tester.pumpAndSettle();
}

void main() {
  group('TutorialRepositoryLocal', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('vale por usuário e por tipo', () async {
      var uid = 'a';
      final repositorio = TutorialRepositoryLocal(uidAtual: () => uid);

      await repositorio.marcarVisto(TipoTutorial.link);
      expect(await repositorio.visto(TipoTutorial.link), isTrue);
      expect(await repositorio.visto(TipoTutorial.print), isFalse);

      uid = 'b';
      expect(await repositorio.visto(TipoTutorial.link), isFalse);
    });

    test('versão anterior do tutorial não vale', () async {
      SharedPreferences.setMockInitialValues({
        TutorialRepositoryLocal.chavePara('a', TipoTutorial.link):
            versaoTutorial[TipoTutorial.link]! - 1,
      });
      final repositorio = TutorialRepositoryLocal(uidAtual: () => 'a');

      expect(await repositorio.visto(TipoTutorial.link), isFalse);
    });

    test('removerDe apaga as marcas do usuário', () async {
      final repositorio = TutorialRepositoryLocal(uidAtual: () => 'a');
      await repositorio.marcarVisto(TipoTutorial.link);
      await repositorio.marcarVisto(TipoTutorial.print);

      await TutorialRepositoryLocal.removerDe('a');

      expect(await repositorio.visto(TipoTutorial.link), isFalse);
      expect(await repositorio.visto(TipoTutorial.print), isFalse);
    });

    test('sem usuário, a leitura falha em vez de inventar um dono', () {
      final repositorio = TutorialRepositoryLocal(uidAtual: () => null);
      expect(repositorio.visto(TipoTutorial.link), throwsStateError);
    });
  });

  group('ExemploTutorialLink', () {
    test('o resultado é o do motor de score, sem números próprios', () {
      for (final exemplo in ExemploTutorialLink.todos) {
        final esperado = CalculadoraScore.calcular(
          SinaisIdentificados(link: exemplo.sinais),
        );
        expect(exemplo.resultado.pontuacao, esperado.pontuacao);
        expect(exemplo.resultado.faixa, esperado.faixa);
      }
    });

    test('os endereços são fictícios, no domínio reservado .example', () {
      for (final exemplo in ExemploTutorialLink.todos) {
        expect(exemplo.endereco, contains('.example'));
      }
    });

    test('mostra as três verificações, com e sem sinal', () {
      final exemplo = ExemploTutorialLink.todos.first;
      expect(exemplo.verificacoes.map((v) => v.sinal), SinalLink.values);
      expect(
        exemplo.verificacoes.where((v) => v.encontrado).map((v) => v.sinal),
        unorderedEquals(exemplo.sinais),
      );
    });

    test('há um exemplo sem nenhum sinal, para mostrar a faixa verde', () {
      expect(
        ExemploTutorialLink.todos.map((e) => e.resultado.faixa),
        contains(FaixaRisco.baixo),
      );
    });
  });

  group('Tutorial na tela de análise de link', () {
    testWidgets('aparece na primeira abertura; Pular grava a marca', (
      tester,
    ) async {
      final tela = _Tela();
      await tela.abrir(tester);

      expect(find.text(_tituloTutorial), findsOneWidget);

      await tester.tap(find.byKey(const Key('tutorial_pular')));
      await tester.pumpAndSettle();

      expect(find.text(_tituloTutorial), findsNothing);
      expect(find.byKey(const Key('analisar_link_url')), findsOneWidget);
      expect(tela.tutorial.vistos, contains(TipoTutorial.link));
    });

    testWidgets('não aparece quando já foi visto', (tester) async {
      final tela = _Tela(tutorial: FakeTutorialRepository());
      await tela.abrir(tester);

      expect(find.text(_tituloTutorial), findsNothing);
      expect(find.byKey(const Key('analisar_link_url')), findsOneWidget);
    });

    testWidgets('se a marca não puder ser lida, não bloqueia a análise', (
      tester,
    ) async {
      final tela = _Tela(
        tutorial: FakeTutorialRepository(vistos: {}, falhaAoLer: true),
      );
      await tela.abrir(tester);

      expect(find.text(_tituloTutorial), findsNothing);
      expect(find.byKey(const Key('analisar_link_url')), findsOneWidget);
    });

    testWidgets('o botão de ajuda reabre o tutorial já visto', (tester) async {
      final tela = _Tela(tutorial: FakeTutorialRepository());
      await tela.abrir(tester);

      await tester.tap(find.byKey(const Key('analisar_link_ajuda')));
      await tester.pumpAndSettle();

      expect(find.text(_tituloTutorial), findsOneWidget);
    });

    testWidgets('Próximo e Voltar percorrem as 4 etapas; "Começar" conclui', (
      tester,
    ) async {
      final tela = _Tela();
      await tela.abrir(tester);

      expect(_etapa(1), findsOneWidget);
      expect(find.byKey(const Key('tutorial_voltar')), findsNothing);
      await _avancar(tester);
      expect(_etapa(2), findsOneWidget);

      await tester.tap(find.byKey(const Key('tutorial_voltar')));
      await tester.pumpAndSettle();
      expect(_etapa(1), findsOneWidget);

      await _avancar(tester);
      await _avancar(tester);
      await _avancar(tester);
      expect(_etapa(4), findsOneWidget);
      expect(find.text(RotulosRisco.avisoPermanente), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);

      await _avancar(tester);
      expect(find.text(_tituloTutorial), findsNothing);
      expect(tela.tutorial.vistos, contains(TipoTutorial.link));
    });

    testWidgets('simulação: copiar, colar, verificar e ver o resultado', (
      tester,
    ) async {
      final tela = _Tela();
      await tela.abrir(tester);
      final principal = ExemploTutorialLink.todos.first;

      // Etapa 1: copiar o link da conversa.
      expect(find.byKey(const Key('tutorial_link_copiado')), findsNothing);
      await _tocar(tester, 'tutorial_chat_link', longo: true);
      expect(find.byKey(const Key('tutorial_link_copiado')), findsOneWidget);
      await _avancar(tester);

      // Etapa 2: "Verificar link" só funciona depois de colar.
      await _tocar(tester, 'tutorial_verificar');
      expect(_etapa(2), findsOneWidget);
      await _tocar(tester, 'tutorial_colar');
      expect(find.text(principal.endereco), findsWidgets);
      await _tocar(tester, 'tutorial_verificar');

      // Etapa 3: as três verificações do exemplo, concluídas uma a uma.
      expect(_etapa(3), findsOneWidget);
      for (final v in principal.verificacoes) {
        expect(find.text(v.texto), findsOneWidget);
      }
      await _tocar(tester, 'tutorial_ver_resultado');

      // Etapa 4: o resultado calculado pelo motor de score.
      expect(_etapa(4), findsOneWidget);
      final noCelular = find.byKey(const Key('tutorial_resultado_exemplo'));
      final resultado = principal.resultado;
      expect(
        find.descendant(of: noCelular, matching: find.text(resultado.rotulo)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: noCelular,
          matching: find.text('${resultado.pontuacao}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('outros exemplos mostram o resultado do motor, sem rede e '
        'sem histórico', (tester) async {
      final tela = _Tela();
      await tela.abrir(tester);
      await _avancar(tester);
      await _avancar(tester);
      await _avancar(tester);

      for (final (i, exemplo) in ExemploTutorialLink.todos.indexed) {
        await _escolherExemplo(tester, i);

        final noCelular = find.byKey(const Key('tutorial_resultado_exemplo'));
        final resultado = exemplo.resultado;
        for (final texto in [
          resultado.faixa.rotulo,
          '${resultado.pontuacao}',
          resultado.faixa.oQueFazer,
          for (final v in exemplo.verificacoes) v.texto,
        ]) {
          expect(
            find.descendant(of: noCelular, matching: find.text(texto)),
            findsOneWidget,
            reason: 'exemplo $i: $texto',
          );
        }
      }

      expect(tela.rdap.chamadas, 0);
      expect(tela.reputacao.chamadas, 0);
      expect(tela.historico.analises, isEmpty);
    });

    testWidgets('nenhuma etapa usa o termo proibido "Seguro"', (tester) async {
      final tela = _Tela();
      await tela.abrir(tester);
      await _tocar(tester, 'tutorial_chat_link');
      expect(find.textContaining(_termoProibido), findsNothing);
      await _avancar(tester);
      await _tocar(tester, 'tutorial_colar');
      expect(find.textContaining(_termoProibido), findsNothing);
      await _avancar(tester);
      expect(find.textContaining(_termoProibido), findsNothing);
      await _avancar(tester);
      for (var i = 0; i < ExemploTutorialLink.todos.length; i++) {
        await _escolherExemplo(tester, i);
        expect(find.textContaining(_termoProibido), findsNothing);
      }
    });

    testWidgets('letra muito grande em celular pequeno, sem estouro', (
      tester,
    ) async {
      _celular(tester);
      final tela = _Tela();
      await tela.abrir(tester, escalaTexto: 1.6);

      await _tocar(tester, 'tutorial_chat_link');
      await _avancar(tester);
      await _tocar(tester, 'tutorial_colar');
      await _tocar(tester, 'tutorial_verificar');
      await _tocar(tester, 'tutorial_ver_resultado');
      for (var i = 0; i < ExemploTutorialLink.todos.length; i++) {
        await _escolherExemplo(tester, i);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('com redução de movimento, nada fica animado', (tester) async {
      final tela = _Tela();
      await tela.abrir(tester, semAnimacao: true);

      await tester.tap(find.byKey(const Key('tutorial_proximo')));
      await tester.pump();
      expect(_etapa(2), findsOneWidget);

      await tester.tap(find.byKey(const Key('tutorial_proximo')));
      await tester.pump();
      await tester.pump();
      // As verificações aparecem concluídas de uma vez.
      final principal = ExemploTutorialLink.todos.first;
      for (final v in principal.verificacoes) {
        expect(find.text(v.texto), findsOneWidget);
      }
      // E o botão para ver o resultado já está disponível.
      await _tocar(tester, 'tutorial_ver_resultado');
      expect(_etapa(4), findsOneWidget);
    });
  });
}
