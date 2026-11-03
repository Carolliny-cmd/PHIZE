import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/historico_repository_firestore.dart';
import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/features/analise/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';

void main() {
  final data = DateTime(2026, 11, 3, 10);
  final doPrint = AnaliseRisco(
    score: 45,
    faixa: FaixaRisco.medio,
    categoria: CategoriaAmeaca.falsoContato,
    explicacao: 'Explicação.',
    tipoEntrada: TipoEntrada.imagem,
    data: data,
  );

  test('grava só a lista fechada de campos (RNF07, etapa 4)', () {
    expect(analiseParaDocumento(doPrint), {
      'score': 45,
      'faixa': 'medio',
      'categoria': 'falso_contato',
      'explicacao': 'Explicação.',
      'tipoEntrada': 'imagem',
      'data': Timestamp.fromDate(data),
    });
  });

  test('análise de link: o campo categoria não existe no documento', () {
    final doLink = AnaliseRisco(
      score: 0,
      faixa: FaixaRisco.baixo,
      categoria: null,
      explicacao: 'Explicação.',
      tipoEntrada: TipoEntrada.link,
      data: data,
    );

    expect(analiseParaDocumento(doLink).containsKey('categoria'), isFalse);
    final lida = analiseDeDocumento('id', analiseParaDocumento(doLink));
    expect(lida?.categoria, isNull);
    expect(lida?.tipoEntrada, TipoEntrada.link);
  });

  test('lê de volta o que gravou', () {
    final lida = analiseDeDocumento('abc', analiseParaDocumento(doPrint));

    expect(lida?.id, 'abc');
    expect(lida?.score, 45);
    expect(lida?.faixa, FaixaRisco.medio);
    expect(lida?.categoria, CategoriaAmeaca.falsoContato);
    expect(lida?.tipoEntrada, TipoEntrada.imagem);
    expect(lida?.data, data);
  });

  test('documento fora do formato não vira registro', () {
    final valido = analiseParaDocumento(doPrint);

    for (final invalido in <Map<String, dynamic>>[
      {},
      {...valido, 'score': '45'},
      {...valido, 'faixa': 'verde'},
      {...valido, 'tipoEntrada': 'audio'},
      {...valido, 'categoria': 'inventada'},
      {...valido, 'data': '2026-11-03'},
      {...valido, 'explicacao': 1},
    ]) {
      expect(analiseDeDocumento('id', invalido), isNull);
    }
  });
}
