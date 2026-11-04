import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/resposta_modelo.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';

Map<String, Object?> _resposta(Object? trechos) => {
  'sinais': ['pedido_financeiro'],
  'categoria': 'falso_contato',
  'explicacao': 'Explicação.',
  'trechos': trechos,
};

void main() {
  test('lê os trechos dos sinais emitidos', () {
    final resposta = RespostaModelo.deJson(
      _resposta([
        {'sinal': 'pedido_financeiro', 'trecho': '  Faz um Pix  '},
      ]),
    );

    expect(resposta?.trechos.single.sinal, SinalTextoPrint.pedidoFinanceiro);
    expect(resposta?.trechos.single.texto, 'Faz um Pix');
  });

  test('item ruim é ignorado sem invalidar a análise', () {
    final resposta = RespostaModelo.deJson(
      _resposta([
        'texto solto',
        {'sinal': 'ameaca', 'trecho': 'sinal não emitido'},
        {'sinal': 'inventado', 'trecho': 'sinal desconhecido'},
        {'sinal': 'pedido_financeiro', 'trecho': 7},
        {'sinal': 'pedido_financeiro', 'trecho': '   '},
        {'sinal': 'pedido_financeiro', 'trecho': 'x' * 201},
        {'sinal': 'pedido_financeiro', 'trecho': 'válido'},
      ]),
    );

    expect(resposta?.trechos.map((t) => t.texto), ['válido']);
  });

  test('sem o campo, ou com outro tipo, não há trechos', () {
    expect(RespostaModelo.deJson(_resposta(null))?.trechos, isEmpty);
    expect(RespostaModelo.deJson(_resposta('x'))?.trechos, isEmpty);
  });
}
