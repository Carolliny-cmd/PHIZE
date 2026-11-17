import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/golpe_da_semana.dart';
import 'package:phize/features/analise/presentation/pages/dashboard_page.dart';
import 'package:phize/features/analise/presentation/pages/golpe_da_semana_page.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

/// Conteúdo fictício nos dublês.
class _Repositorio implements GolpeDaSemanaRepository {
  _Repositorio(this._fichas, {this.falha = false});

  final List<FichaEducativa> _fichas;
  final bool falha;

  @override
  Future<List<FichaEducativa>> fichas() async {
    if (falha) throw Exception('arquivo ausente');
    return _fichas;
  }
}

const _ficha = FichaEducativa(
  id: 'falso-teste',
  modalidade: 'Falso teste de golpe',
  categoria: CategoriaAmeaca.falsoContato,
  canais: ['WhatsApp', 'SMS'],
  frasesComuns: ['troquei de número', 'me manda um Pix'],
  oQuePedem: 'Pix para conta de terceiro.',
  oQueFazer: 'Ligue para o número antigo antes de pagar.',
  fontes: [(publicador: 'Fonte pública', titulo: 'Alerta de exemplo')],
);

Future<void> _abrir(WidgetTester tester, GolpeDaSemanaRepository repo) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DashboardPage(golpeDaSemanaRepository: repo),
      onGenerateRoute: AppRouter.onGenerateRoute,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o Início mostra o golpe da semana com uma frase', (
    tester,
  ) async {
    await _abrir(tester, _Repositorio([_ficha]));
    expect(find.text('Golpe da semana'), findsOneWidget);
    expect(find.text('Falso teste de golpe'), findsOneWidget);
    expect(find.text('"troquei de número"'), findsOneWidget);
  });

  testWidgets('tocar abre sinais, pedido, orientação e fonte', (tester) async {
    await _abrir(tester, _Repositorio([_ficha]));
    await tester.ensureVisible(find.byKey(const Key('golpe_da_semana')));
    await tester.tap(find.byKey(const Key('golpe_da_semana')));
    await tester.pumpAndSettle();

    expect(find.byType(GolpeDaSemanaPage), findsOneWidget);
    expect(find.text('Chega por: WhatsApp, SMS'), findsOneWidget);
    expect(find.text('"me manda um Pix"'), findsOneWidget);
    expect(find.text('Pix para conta de terceiro.'), findsOneWidget);
    expect(
      find.text('Ligue para o número antigo antes de pagar.'),
      findsOneWidget,
    );
    expect(find.textContaining('Fonte pública'), findsOneWidget);
    expect(find.text(GolpeDaSemanaPage.nota), findsOneWidget);
  });

  testWidgets('sem conteúdo, o Início segue sem o cartão', (tester) async {
    await _abrir(tester, _Repositorio(const [], falha: true));
    expect(find.byKey(const Key('golpe_da_semana')), findsNothing);
    expect(find.byKey(const Key('dashboard_analisar_link')), findsOneWidget);
  });

  testWidgets('o arquivo real do app carrega no Início', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('golpe_da_semana')), findsOneWidget);
  });
}
