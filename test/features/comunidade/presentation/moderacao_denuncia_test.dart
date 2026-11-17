import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/comunidade/domain/motivo_denuncia.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/features/comunidade/presentation/pages/moderacao_page.dart';

import '../../../support/fake_feed_repository.dart';

/// Conteúdo fictício em todos os casos.
Future<void> _abrir(
  WidgetTester tester, {
  FakeFeedRepository? feed,
  FakeModeracaoRepository? moderacao,
  String rota = AppRoutes.comunidade,
  Object? argumentos,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings.name == '/'
            ? RouteSettings(name: rota, arguments: argumentos)
            : settings,
        feedRepository: feed ?? FakeFeedRepository(),
        compartilhadorTexto: FakeCompartilhadorTexto(),
        moderacaoRepository:
            moderacao ?? FakeModeracaoRepository(moderador: false),
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

ReporteComunidade _oculto() => reporteDeTeste(
  id: 'o1',
  titulo: 'Acusação contra loja',
  status: StatusReporte.oculto,
  denuncias: 3,
);

void main() {
  group('denúncia (RF11)', () {
    testWidgets('denunciar grava o motivo e não deixa repetir', (tester) async {
      final feed = FakeFeedRepository();
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      await _tocar(tester, find.byKey(const Key('detalhe_denunciar')));
      expect(find.text('Por que denunciar?'), findsOneWidget);
      for (final motivo in MotivoDenuncia.values) {
        expect(find.text(motivo.nome), findsOneWidget);
      }

      await _tocar(
        tester,
        find.byKey(const Key('motivo_acusa_organizacao_legitima')),
      );
      expect(feed.denunciados, {'r1': MotivoDenuncia.acusaOrganizacaoLegitima});
      expect(find.textContaining('Denúncia enviada'), findsOneWidget);
      expect(find.text('Você denunciou este reporte'), findsOneWidget);
      final botao = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('detalhe_denunciar')),
      );
      expect(botao.onPressed, isNull);
    });

    testWidgets('cancelar não denuncia', (tester) async {
      final feed = FakeFeedRepository();
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      await _tocar(tester, find.byKey(const Key('detalhe_denunciar')));
      await _tocar(tester, find.text('Cancelar'));
      expect(feed.denunciados, isEmpty);
      expect(find.text('Denunciar este reporte'), findsOneWidget);
    });

    testWidgets('quem já denunciou vê o botão desativado', (tester) async {
      final feed = FakeFeedRepository(
        denunciados: {'r1': MotivoDenuncia.falso},
      );
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      expect(find.text('Você denunciou este reporte'), findsOneWidget);
    });

    testWidgets('falha ao denunciar avisa e permite tentar de novo', (
      tester,
    ) async {
      final feed = FakeFeedRepository(falhaAoDenunciar: true);
      await _abrir(
        tester,
        feed: feed,
        rota: AppRoutes.detalheReporte,
        argumentos: feed.reportes.single,
      );
      await _tocar(tester, find.byKey(const Key('detalhe_denunciar')));
      await _tocar(tester, find.byKey(const Key('motivo_falso')));
      expect(find.textContaining('Não foi possível enviar'), findsOneWidget);
      expect(find.text('Denunciar este reporte'), findsOneWidget);
    });
  });

  group('moderação (RF11)', () {
    testWidgets('conta comum não vê a entrada da moderação', (tester) async {
      await _abrir(tester);
      expect(find.byKey(const Key('comunidade_moderacao')), findsNothing);
    });

    testWidgets('moderadora abre a moderação pelos ocultos', (tester) async {
      await _abrir(
        tester,
        moderacao: FakeModeracaoRepository(
          reportes: [_oculto()],
          motivos: {MotivoDenuncia.acusaOrganizacaoLegitima: 3},
        ),
      );
      await _tocar(tester, find.byKey(const Key('comunidade_moderacao')));

      expect(find.byType(ModeracaoPage), findsOneWidget);
      expect(find.text('Acusação contra loja'), findsOneWidget);
      expect(find.textContaining('3 denúncia(s)'), findsOneWidget);
      expect(
        find.text('Acusa uma empresa ou órgão legítimo: 3'),
        findsOneWidget,
      );
      // Já oculto: não oferece "Ocultar".
      expect(find.byKey(const Key('moderacao_ocultar_o1')), findsNothing);
    });

    testWidgets('aprovar tira o reporte dos ocultos', (tester) async {
      final moderacao = FakeModeracaoRepository(reportes: [_oculto()]);
      await _abrir(tester, rota: AppRoutes.moderacao, moderacao: moderacao);
      await _tocar(tester, find.byKey(const Key('moderacao_aprovar_o1')));

      expect(moderacao.mudancas, [('o1', StatusReporte.aprovado)]);
      expect(find.text('Reporte aprovado.'), findsOneWidget);
      expect(find.text('Nenhum reporte nesta lista.'), findsOneWidget);

      await _tocar(tester, find.text('Aprovados'));
      expect(find.text('Acusação contra loja'), findsOneWidget);
    });

    testWidgets('ocultar um pendente', (tester) async {
      final moderacao = FakeModeracaoRepository(reportes: [reporteDeTeste()]);
      await _abrir(tester, rota: AppRoutes.moderacao, moderacao: moderacao);
      await _tocar(tester, find.text('Pendentes'));
      await _tocar(tester, find.byKey(const Key('moderacao_ocultar_r1')));
      expect(moderacao.mudancas, [('r1', StatusReporte.oculto)]);
    });

    testWidgets('excluir pede confirmação', (tester) async {
      final moderacao = FakeModeracaoRepository(reportes: [_oculto()]);
      await _abrir(tester, rota: AppRoutes.moderacao, moderacao: moderacao);

      await _tocar(tester, find.byKey(const Key('moderacao_excluir_o1')));
      await _tocar(tester, find.text('Cancelar'));
      expect(moderacao.excluidos, isEmpty);

      await _tocar(tester, find.byKey(const Key('moderacao_excluir_o1')));
      expect(find.textContaining('Não dá para desfazer'), findsOneWidget);
      await _tocar(
        tester,
        find.byKey(const Key('moderacao_confirmar_exclusao')),
      );
      expect(moderacao.excluidos, ['o1']);
      expect(find.text('Reporte excluído.'), findsOneWidget);
    });
  });
}
