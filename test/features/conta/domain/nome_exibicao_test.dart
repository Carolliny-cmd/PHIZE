import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/conta/domain/nome_exibicao.dart';

void main() {
  test('tira espaços das pontas e repetidos no meio', () {
    expect(normalizarNomeExibicao('  Maria   da  Silva '), 'Maria da Silva');
  });

  test('vazio ou só espaços vira "sem nome"', () {
    expect(normalizarNomeExibicao(''), isNull);
    expect(normalizarNomeExibicao('   '), isNull);
    expect(validarNomeExibicao('   '), isNull);
  });

  test('aceita até o limite, depois de normalizar', () {
    final noLimite = 'a' * limiteNomeExibicao;
    expect(validarNomeExibicao(noLimite), isNull);
    expect(validarNomeExibicao('  $noLimite  '), isNull);
    expect(validarNomeExibicao('${noLimite}b'), isNotNull);
  });

  test('não exige nome real: apelido e número são aceitos', () {
    expect(validarNomeExibicao('Vó Neuza'), isNull);
    expect(validarNomeExibicao('Tio 2'), isNull);
  });
}
