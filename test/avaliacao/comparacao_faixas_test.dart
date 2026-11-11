import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';

import 'comparacao_faixas.dart';

RodadaRelatorio _rodada(
  String mensagem,
  String modo,
  List<String> sinais, {
  String grupo = 'golpe',
  String? esperado = 'ficha',
  String? padrao,
}) =>
    RodadaRelatorio(
      mensagem: mensagem,
      grupo: grupo,
      modo: modo,
      sinais: sinais,
      padrao: padrao,
      esperado: esperado,
    );

void main() {
  test('sem sinal é verde; sinal desconhecido é ignorado', () {
    expect(faixaDosSinais(const []), FaixaRisco.baixo);
    expect(faixaDosSinais(const ['sinal_inexistente']), FaixaRisco.baixo);
  });

  test('usa o motor do app: mais sinais nunca baixam a faixa', () {
    final um = faixaDosSinais(const ['inducao_urgencia']);
    final dois = faixaDosSinais(
      const ['inducao_urgencia', 'correspondencia_padrao_catalogado'],
    );
    expect(um, isNot(FaixaRisco.baixo));
    expect(dois.index, greaterThanOrEqualTo(um.index));
  });

  test('marca golpe que sobe de faixa com a base', () {
    final faixas = faixasPorMensagem([
      _rodada('m', 'sem_base', const ['inducao_urgencia']),
      _rodada('m', 'com_base',
          const ['inducao_urgencia', 'correspondencia_padrao_catalogado',
              'solicitacao_dados_pessoais'],
          padrao: 'ficha'),
    ]);
    expect(faixas.single.subiu, isTrue);
    expect(faixas.single.padraoComBase, 'ficha');
    final resumo = resumirFaixas(faixas);
    expect(resumo[TipoMensagem.golpeDaBase]!.subiram, ['m']);
  });

  test('separa golpe fora da base e mensagem legítima', () {
    final faixas = faixasPorMensagem([
      _rodada('fora', 'sem_base', const [], esperado: null),
      _rodada('fora', 'com_base', const [], esperado: null),
      _rodada('leg', 'sem_base', const [], grupo: 'legitima', esperado: null),
      _rodada('leg', 'com_base', const [], grupo: 'legitima', esperado: null),
    ]);
    expect(faixas.map((f) => f.tipo),
        [TipoMensagem.golpeForaDaBase, TipoMensagem.legitima]);
  });

  test('empate entre repetições fica com a faixa mais alta', () {
    final faixas = faixasPorMensagem([
      _rodada('m', 'sem_base', const []),
      _rodada('m', 'sem_base', const ['inducao_urgencia']),
      _rodada('m', 'com_base', const []),
      _rodada('m', 'com_base', const []),
    ]);
    expect(faixas.single.semBase, isNot(FaixaRisco.baixo));
    expect(faixas.single.comBase, FaixaRisco.baixo);
    expect(faixas.single.desceu, isTrue);
  });

  test('mensagem sem rodada em um dos modos fica fora da contagem', () {
    final resumo = resumirFaixas(faixasPorMensagem([
      _rodada('m', 'com_base', const ['ameaca']),
    ]));
    expect(resumo[TipoMensagem.golpeDaBase]!.total, 0);
  });
}
