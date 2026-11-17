import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/features/comunidade/presentation/pages/comunidade_page.dart';
import 'package:phize/features/comunidade/presentation/pages/detalhe_reporte_page.dart';

import '../../../support/fake_feed_repository.dart';

/// Conteúdo fictício em todos os casos.
Future<void> _abrir(
  WidgetTester tester, {
  required FakeFeedRepository feed,
  FakeCompartilhadorTexto? compartilhador,
  String rota = AppRoutes.comunidade,
  Object? argumentos,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings.name == '/'
            ? RouteSettings(name: rota, arguments: argumentos)
            : settings,
        feedRepository: feed,
        compartilhadorTexto: compartilhador ?? FakeCompartilhadorTexto(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _antigo = reporteDeTeste(
  id: 'antigo',
  titulo: 'Boleto falso de condomínio',
  categoria: reporteDeTeste().categoria,
  curtidas: 9,
  criadoEm: DateTime(2026, 11, 1),
);
final _novo = reporteDeTeste(
  id: 'novo',
  titulo: 'Falsa central do banco',
  curtidas: 1,
  status: StatusReporte.aprovado,
  criadoEm: DateTime(2026, 11, 16),
);

void main() {
  group('feed (RF08)', () {
    testWidgets('mostra título, data e curtidas, começando por "Em alta"', (
      tester,
    ) async {
      final feed = FakeFeedRepository(reportes: [_novo, _antigo]);
      await _abrir(tester, feed: feed);

      expect(feed.ordensPedidas, [OrdemFeed.emAlta]);
      expect(find.text(ComunidadePage.avisoFeed), findsOneWidget);
      expect(find.text('Boleto falso de condomínio'), findsOneWidget);
      expect(find.textContaining('01/11/2026'), findsOneWidget);
      expect(find.text('9 curtidas'), findsOneWidget);
      expect(find.text('1 curtida'), findsOneWidget);
      // O mais curtido vem primeiro.
      expect(
        tester.getTopLeft(find.text('Boleto falso de condomínio')).dy,
        lessThan(tester.getTopLeft(find.text('Falsa central do banco')).dy),
      );
      // Só o pendente leva a marca.
      expect(find.text('Ainda não revisado'), findsOneWidget);
    });

    testWidgets('"Mais recentes" pede a outra ordem', (tester) async {
      final feed = FakeFeedRepository(reportes: [_antigo, _novo]);
      await _abrir(tester, feed: feed);
      await tester.tap(find.text('Mais recentes'));
      await tester.pumpAndSettle();

      expect(feed.ordensPedidas.last, OrdemFeed.maisRecentes);
      expect(
        tester.getTopLeft(find.text('Falsa central do banco')).dy,
        lessThan(tester.getTopLeft(find.text('Boleto falso de condomínio')).dy),
      );
    });

    testWidgets('feed vazio convida a reportar', (tester) async {
      await _abrir(tester, feed: FakeFeedRepository(reportes: []));
      expect(find.textContaining('Ainda não há reportes'), findsOneWidget);
      expect(find.byKey(const Key('comunidade_reportar')), findsOneWidget);
    });

    testWidgets('falha de conexão oferece tentar de novo', (tester) async {
      final feed = FakeFeedRepository(falhaAoListar: true);
      await _abrir(tester, feed: feed);
      expect(find.textContaining('Não foi possível carregar'), findsOneWidget);

      feed.falhaAoListar = false;
      await tester.tap(find.byKey(const Key('comunidade_tentar_de_novo')));
      await tester.pumpAndSettle();
      expect(find.text('Falso parente pedindo Pix'), findsOneWidget);
    });

    testWidgets('a aba Comunidade é a segunda da barra', (tester) async {
      await _abrir(tester, feed: FakeFeedRepository());
      final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(barra.destinations, hasLength(4));
      expect(barra.selectedIndex, 1);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Comunidade'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"Reportar golpe" abre a tela de reporte', (tester) async {
      await _abrir(tester, feed: FakeFeedRepository());
      await tester.tap(find.byKey(const Key('comunidade_reportar')));
      await tester.pumpAndSettle();
      expect(find.text('Reportar golpe'), findsWidgets);
      expect(find.byType(ComunidadePage), findsNothing);
    });
  });

  group('detalhe, curtir e compartilhar (RF06, RF09)', () {
    testWidgets('tocar no reporte abre o detalhe, sem autor', (tester) async {
      await _abrir(tester, feed: FakeFeedRepository());
      await tester.tap(find.text('Falso parente pedindo Pix'));
      await tester.pumpAndSettle();

      expect(find.byType(DetalheReportePage), findsOneWidget);
      expect(find.textContaining('Usuário do Phize'), findsOneWidget);
      expect(find.textContaining('trocou de celular'), findsOneWidget);
      expect(find.text('2 pessoas relataram este golpe.'), findsOneWidget);
      expect(find.text(DetalheReportePage.avisoComunidade), findsOneWidget);
    });

    testWidgets('curtir soma 1 e não deixa curtir de novo', (tester) async {
      final feed = FakeFeedRepository();
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      expect(find.text('3 curtidas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('detalhe_curtir')));
      await tester.pumpAndSettle();

      expect(feed.curtidos, {'r1'});
      expect(find.text('4 curtidas'), findsOneWidget);
      expect(find.text('Você curtiu'), findsOneWidget);
      final botao = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('detalhe_curtir')),
      );
      expect(botao.onPressed, isNull);
    });

    testWidgets('quem já curtiu vê o botão desativado', (tester) async {
      final feed = FakeFeedRepository(curtidos: {'r1'});
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      expect(find.text('Você curtiu'), findsOneWidget);
      final botao = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('detalhe_curtir')),
      );
      expect(botao.onPressed, isNull);
    });

    testWidgets('falha ao curtir avisa e mantém a contagem', (tester) async {
      final feed = FakeFeedRepository(falhaAoCurtir: true);
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      await tester.tap(find.byKey(const Key('detalhe_curtir')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Não foi possível registrar'), findsOneWidget);
      expect(find.text('3 curtidas'), findsOneWidget);
    });

    testWidgets('a curtida aparece no feed ao voltar', (tester) async {
      await _abrir(tester, feed: FakeFeedRepository());
      await tester.tap(find.text('Falso parente pedindo Pix'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detalhe_curtir')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('4 curtidas'), findsOneWidget);
    });

    testWidgets('compartilhar envia a mensagem padronizada', (tester) async {
      final compartilhador = FakeCompartilhadorTexto();
      final reporte = reporteDeTeste(tipo: TipoReporte.link, relato: '');
      await _abrir(
        tester,
        feed: FakeFeedRepository(reportes: [reporte]),
        compartilhador: compartilhador,
        rota: AppRoutes.detalheReporte,
        argumentos: reporte,
      );
      expect(find.textContaining('não guarda nem mostra'), findsOneWidget);

      await tester.tap(find.byKey(const Key('detalhe_compartilhar')));
      await tester.pumpAndSettle();
      expect(compartilhador.enviados.single, startsWith('Alerta de golpe'));
      expect(compartilhador.enviados.single, contains(reporte.titulo));
    });
  });
}
