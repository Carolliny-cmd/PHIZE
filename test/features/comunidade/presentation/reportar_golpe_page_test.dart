import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/preparacao_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_repository.dart';
import 'package:phize/features/comunidade/presentation/pages/reportar_golpe_page.dart';
import 'package:phize/shared/domain/captura_imagem.dart';
import 'package:phize/shared/domain/imagem_em_memoria.dart';
import 'package:phize/shared/domain/reconhecedor_texto.dart';
import 'package:phize/shared/domain/seletor_imagem.dart';

/// Conteúdo fictício em todos os casos.
class _RepositorioFalso implements ReporteRepository {
  _RepositorioFalso({
    this.resultado = ResultadoPublicacao.publicado,
    this.erro,
  });

  final ResultadoPublicacao resultado;
  final Object? erro;
  final List<NovoReporte> publicados = [];

  @override
  Future<ResultadoPublicacao> publicar(NovoReporte reporte) async {
    if (erro case final e?) throw e;
    publicados.add(reporte);
    return resultado;
  }
}

class _ArquivoFalso implements ArquivoSelecionado {
  final Uint8List bytes = Uint8List.fromList([7, 7, 7, 7]);
  bool removido = false;

  @override
  Future<Uint8List> lerBytes() async => bytes;

  @override
  Future<void> remover() async => removido = true;
}

class _SeletorFalso implements SeletorImagem {
  _SeletorFalso(this.arquivo);

  final ArquivoSelecionado? arquivo;

  @override
  Future<ArquivoSelecionado?> selecionar() async => arquivo;

  @override
  Future<List<ArquivoSelecionado>> recuperarResiduos() async => const [];
}

class _ReconhecedorFalso implements ReconhecedorTexto {
  _ReconhecedorFalso(this.texto);

  final String texto;
  ImagemEmMemoria? recebida;

  @override
  Future<String> reconhecer(ImagemEmMemoria imagem) async {
    recebida = imagem;
    return texto;
  }
}

Future<_RepositorioFalso> _abrir(
  WidgetTester tester, {
  _RepositorioFalso? repositorio,
  ArquivoSelecionado? arquivo,
  String textoPrint = '',
  _ReconhecedorFalso? reconhecedor,
}) async {
  final repo = repositorio ?? _RepositorioFalso();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportarGolpePage(
                captura: CapturaImagem(_SeletorFalso(arquivo)),
                reconhecedor: reconhecedor ?? _ReconhecedorFalso(textoPrint),
                repositorio: repo,
              ),
            ),
          ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _publicar(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('reportar_publicar')));
  await tester.tap(find.byKey(const Key('reportar_publicar')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('avisa que o reporte é público e pede só conteúdo de teste', (
    tester,
  ) async {
    await _abrir(tester);
    expect(find.text(ReportarGolpePage.avisoPublico), findsOneWidget);
  });

  testWidgets('link: publica só a hash e mostra o agradecimento', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    await tester.enterText(
      find.byKey(const Key('reportar_link')),
      'https://entrega-taxa.example/pagar',
    );
    await tester.enterText(
      find.byKey(const Key('reportar_titulo')),
      'Entrega com taxa',
    );
    await _publicar(tester);

    final publicado = repo.publicados.single;
    expect(publicado.tipo, TipoReporte.link);
    expect(publicado.hashLink, hashDoLink('entrega-taxa.example'));
    expect(publicado.titulo, 'Entrega com taxa');
    expect(find.byKey(const Key('reportar_resultado')), findsOneWidget);
    expect(find.textContaining('aguarda revisão'), findsOneWidget);

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportarGolpePage), findsNothing);
  });

  testWidgets('domínio oficial é recusado com explicação, sem publicar', (
    tester,
  ) async {
    final repo = await _abrir(tester);
    await tester.enterText(
      find.byKey(const Key('reportar_link')),
      'https://www.itau.com.br',
    );
    await tester.enterText(
      find.byKey(const Key('reportar_titulo')),
      'Banco pedindo senha',
    );
    await _publicar(tester);

    expect(repo.publicados, isEmpty);
    expect(
      find.text(MotivoRecusaReporte.dominioOficial.mensagem),
      findsOneWidget,
    );
  });

  testWidgets('link já reportado conta como mais um caso', (tester) async {
    await _abrir(
      tester,
      repositorio: _RepositorioFalso(
        resultado: ResultadoPublicacao.incidenciaRegistrada,
      ),
    );
    await tester.enterText(
      find.byKey(const Key('reportar_link')),
      'entrega-taxa.example',
    );
    await tester.enterText(
      find.byKey(const Key('reportar_titulo')),
      'Entrega com taxa',
    );
    await _publicar(tester);
    expect(find.textContaining('mais um caso'), findsOneWidget);
  });

  testWidgets('falha de envio mantém o reporte na tela para nova tentativa', (
    tester,
  ) async {
    final repo = await _abrir(
      tester,
      repositorio: _RepositorioFalso(erro: Exception('sem rede')),
    );
    await tester.tap(find.text('Relato'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reportar_titulo')),
      'Falso parente',
    );
    await tester.enterText(
      find.byKey(const Key('reportar_relato')),
      'Pediu Pix dizendo que trocou de número.',
    );
    await _publicar(tester);

    expect(repo.publicados, isEmpty);
    expect(find.textContaining('Não foi possível enviar'), findsOneWidget);
    expect(find.text('Falso parente'), findsOneWidget);
    expect(find.textContaining('trocou de número'), findsOneWidget);
  });

  testWidgets('print: o texto lido aparece mascarado e a imagem é descartada', (
    tester,
  ) async {
    final arquivo = _ArquivoFalso();
    final reconhecedor = _ReconhecedorFalso(
      'Oi, meu CPF é 123.456.789-09. Paga em https://golpe.example/x',
    );
    final repo = await _abrir(
      tester,
      arquivo: arquivo,
      reconhecedor: reconhecedor,
    );
    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reportar_escolher_print')));
    await tester.pumpAndSettle();

    final relato = tester
        .widget<TextField>(find.byKey(const Key('reportar_relato')))
        .controller!
        .text;
    expect(relato, contains('[CPF]'));
    expect(relato, contains('[LINK]'));
    expect(relato, isNot(contains('123.456')));
    expect(relato, isNot(contains('golpe.example')));
    // A imagem foi zerada e o temporário removido (RNF01).
    expect(arquivo.removido, isTrue);
    expect(reconhecedor.recebida, isNotNull);
    expect(arquivo.bytes.every((b) => b == 0), isTrue);

    await tester.enterText(
      find.byKey(const Key('reportar_titulo')),
      'Pedido de CPF',
    );
    await _publicar(tester);
    expect(repo.publicados.single.tipo, TipoReporte.print);
    expect(repo.publicados.single.relato, relato);
  });

  testWidgets('print sem texto avisa e não preenche', (tester) async {
    await _abrir(tester, arquivo: _ArquivoFalso(), textoPrint: '   ');
    await tester.tap(find.text('Print'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reportar_escolher_print')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Não encontramos texto'), findsOneWidget);
  });

  testWidgets('"Colar" preenche o link', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (chamada) async => chamada.method == 'Clipboard.getData'
          ? {'text': 'entrega-taxa.example'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _abrir(tester);
    await tester.tap(find.byKey(const Key('reportar_colar')));
    await tester.pumpAndSettle();
    expect(find.text('entrega-taxa.example'), findsOneWidget);
  });
}
