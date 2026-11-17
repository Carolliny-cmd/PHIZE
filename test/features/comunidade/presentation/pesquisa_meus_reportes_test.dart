import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/comunidade/domain/meus_reportes_repository.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/preparacao_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/features/comunidade/presentation/pages/detalhe_reporte_page.dart';
import 'package:phize/features/comunidade/presentation/pages/meus_reportes_page.dart';
import 'package:phize/features/comunidade/presentation/pages/pesquisa_comunidade_page.dart';
import 'package:phize/features/comunidade/presentation/pages/reportar_golpe_page.dart';

import '../../../support/fake_feed_repository.dart';
import '../../../support/fake_meus_reportes_repository.dart';

/// Conteúdo fictício em todos os casos.
Future<void> _abrir(
  WidgetTester tester, {
  FakeFeedRepository? feed,
  FakeMeusReportesRepository? meus,
  String rota = AppRoutes.comunidade,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings.name == '/' ? RouteSettings(name: rota) : settings,
        feedRepository: feed ?? FakeFeedRepository(),
        compartilhadorTexto: FakeCompartilhadorTexto(),
        moderacaoRepository: FakeModeracaoRepository(moderador: false),
        meusReportesRepository: meus ?? FakeMeusReportesRepository(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

Future<void> _pesquisar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byKey(const Key('pesquisa_campo')), texto);
  await _tocar(tester, find.byKey(const Key('pesquisa_buscar')));
}

final _link = reporteDeTeste(
  id: 'h1',
  tipo: TipoReporte.link,
  titulo: 'Entrega com taxa de reenvio',
  relato: '',
);

MeuReporte _meu(ReporteComunidade? reporte, {String id = 'r1'}) =>
    MeuReporte(id: id, publicadoEm: DateTime(2026, 11, 16), reporte: reporte);

void main() {
  group('pesquisa (RF15)', () {
    testWidgets('a lupa da Comunidade abre a pesquisa', (tester) async {
      await _abrir(tester);
      await _tocar(tester, find.byKey(const Key('comunidade_pesquisar')));
      expect(find.byType(PesquisaComunidadePage), findsOneWidget);
      expect(find.text(PesquisaComunidadePage.ajuda), findsOneWidget);
    });

    testWidgets('link: acha o reporte pela hash e abre o detalhe', (
      tester,
    ) async {
      final feed = FakeFeedRepository(reportes: [_link])
        ..hashes = {'h1': hashDoLink('entrega-taxa.example')!};
      await _abrir(tester, feed: feed, rota: AppRoutes.pesquisaComunidade);
      await _pesquisar(tester, 'https://www.entrega-taxa.example/pagar?id=9');

      expect(find.text('Entrega com taxa de reenvio'), findsOneWidget);
      await _tocar(tester, find.text('Entrega com taxa de reenvio'));
      expect(find.byType(DetalheReportePage), findsOneWidget);
    });

    testWidgets('link validado pela equipe avisa, mesmo sem reporte', (
      tester,
    ) async {
      final feed = FakeFeedRepository(reportes: [])
        ..ameacas = {hashDoLink('golpe-validado.example')!};
      await _abrir(tester, feed: feed, rota: AppRoutes.pesquisaComunidade);
      await _pesquisar(tester, 'golpe-validado.example');

      expect(find.byKey(const Key('pesquisa_validado')), findsOneWidget);
      expect(find.byKey(const Key('pesquisa_sem_resultado')), findsNothing);
    });

    testWidgets('sem resultado sugere reportar (RF15)', (tester) async {
      await _abrir(
        tester,
        feed: FakeFeedRepository(reportes: []),
        rota: AppRoutes.pesquisaComunidade,
      );
      await _pesquisar(tester, 'nada-reportado.example');
      expect(find.textContaining('Ninguém reportou este link'), findsOneWidget);

      await _tocar(tester, find.byKey(const Key('pesquisa_reportar')));
      expect(find.byType(ReportarGolpePage), findsOneWidget);
    });

    testWidgets('palavras acham título e categoria; oculto não aparece', (
      tester,
    ) async {
      final feed = FakeFeedRepository(
        reportes: [
          reporteDeTeste(id: 'a', titulo: 'Boleto falso de condomínio'),
          reporteDeTeste(
            id: 'b',
            titulo: 'Boleto escondido',
            status: StatusReporte.oculto,
          ),
          reporteDeTeste(id: 'c', titulo: 'Outra coisa'),
        ],
      );
      await _abrir(tester, feed: feed, rota: AppRoutes.pesquisaComunidade);
      await _pesquisar(tester, 'Boleto');

      expect(feed.palavrasPesquisadas.single, ['boleto']);
      expect(find.text('Boleto falso de condomínio'), findsOneWidget);
      expect(find.text('Boleto escondido'), findsNothing);
      expect(find.text('Outra coisa'), findsNothing);
    });

    testWidgets('texto curto demais pede outra pesquisa', (tester) async {
      final feed = FakeFeedRepository();
      await _abrir(tester, feed: feed, rota: AppRoutes.pesquisaComunidade);
      await _pesquisar(tester, 'a b');
      expect(find.textContaining('pelo menos 3 letras'), findsOneWidget);
      expect(feed.palavrasPesquisadas, isEmpty);
    });

    testWidgets('falha de conexão oferece tentar de novo', (tester) async {
      await _abrir(
        tester,
        feed: FakeFeedRepository(falhaAoListar: true),
        rota: AppRoutes.pesquisaComunidade,
      );
      await _pesquisar(tester, 'boleto');
      expect(find.textContaining('Não foi possível pesquisar'), findsOneWidget);
    });
  });

  group('Meus reportes (RF16)', () {
    testWidgets('abre pela Comunidade e mostra a situação de cada um', (
      tester,
    ) async {
      final meus = FakeMeusReportesRepository(
        reportes: [
          _meu(reporteDeTeste(id: 'r1', titulo: 'Pendente aqui')),
          _meu(
            reporteDeTeste(
              id: 'r2',
              titulo: 'Oculto aqui',
              status: StatusReporte.oculto,
            ),
            id: 'r2',
          ),
          _meu(null, id: 'r3'),
        ],
      );
      await _abrir(tester, meus: meus);
      await _tocar(tester, find.byKey(const Key('comunidade_meus_reportes')));

      expect(find.byType(MeusReportesPage), findsOneWidget);
      expect(find.text('Aguardando revisão da equipe'), findsOneWidget);
      expect(find.text('Fora do feed, em revisão pela equipe'), findsOneWidget);
      expect(find.text('Removido pela moderação'), findsOneWidget);
      // Removido: não edita, só sai da lista.
      expect(find.byKey(const Key('meus_editar_r3')), findsNothing);
      expect(find.text('Remover da lista'), findsOneWidget);
    });

    testWidgets('sem reportes, avisa', (tester) async {
      await _abrir(tester, rota: AppRoutes.meusReportes);
      expect(find.text('Você ainda não publicou reportes.'), findsOneWidget);
    });

    testWidgets('editar mascara de novo e salva título e relato', (
      tester,
    ) async {
      final meus = FakeMeusReportesRepository(
        reportes: [_meu(reporteDeTeste())],
      );
      await _abrir(tester, meus: meus, rota: AppRoutes.meusReportes);
      await _tocar(tester, find.byKey(const Key('meus_editar_r1')));

      await tester.enterText(
        find.byKey(const Key('editar_relato')),
        'Pediu Pix e o CPF 123.456.789-09.',
      );
      await _tocar(tester, find.byKey(const Key('editar_salvar')));

      final (id, edicao) = meus.edicoes.single;
      expect(id, 'r1');
      expect(edicao.relato, 'Pediu Pix e o CPF [CPF].');
      expect(find.text('Alterações salvas.'), findsOneWidget);
    });

    testWidgets('edição recusada explica e não salva', (tester) async {
      final meus = FakeMeusReportesRepository(
        reportes: [_meu(reporteDeTeste())],
      );
      await _abrir(tester, meus: meus, rota: AppRoutes.meusReportes);
      await _tocar(tester, find.byKey(const Key('meus_editar_r1')));
      await tester.enterText(find.byKey(const Key('editar_titulo')), 'ab');
      await _tocar(tester, find.byKey(const Key('editar_salvar')));

      expect(meus.edicoes, isEmpty);
      expect(
        find.text(MotivoRecusaReporte.tituloCurto.mensagem),
        findsOneWidget,
      );
    });

    testWidgets('reporte de link: o link não é editável', (tester) async {
      final meus = FakeMeusReportesRepository(
        reportes: [_meu(_link, id: 'h1')],
      );
      await _abrir(tester, meus: meus, rota: AppRoutes.meusReportes);
      await _tocar(tester, find.byKey(const Key('meus_editar_h1')));
      expect(
        find.textContaining('O link não pode ser alterado'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('excluir pede confirmação irreversível', (tester) async {
      final meus = FakeMeusReportesRepository(
        reportes: [_meu(_link, id: 'h1')],
      );
      await _abrir(tester, meus: meus, rota: AppRoutes.meusReportes);

      await _tocar(tester, find.byKey(const Key('meus_excluir_h1')));
      expect(find.textContaining('Não dá para desfazer'), findsOneWidget);
      expect(find.textContaining('essa confirmação continua'), findsOneWidget);
      await _tocar(tester, find.text('Cancelar'));
      expect(meus.excluidos, isEmpty);

      await _tocar(tester, find.byKey(const Key('meus_excluir_h1')));
      await _tocar(tester, find.byKey(const Key('meus_confirmar_exclusao')));
      expect(meus.excluidos, ['h1']);
      expect(find.text('Reporte excluído.'), findsOneWidget);
      expect(find.text('Você ainda não publicou reportes.'), findsOneWidget);
    });

    testWidgets('removido pela moderação: só apaga a autoria', (tester) async {
      final meus = FakeMeusReportesRepository(reportes: [_meu(null)]);
      await _abrir(tester, meus: meus, rota: AppRoutes.meusReportes);
      await _tocar(tester, find.byKey(const Key('meus_excluir_r1')));
      await _tocar(tester, find.byKey(const Key('meus_confirmar_exclusao')));
      expect(meus.esquecidos, ['r1']);
      expect(meus.excluidos, isEmpty);
    });
  });
}
