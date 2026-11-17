import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/resultado_analise_link.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/verificacao_link.dart';

VerificacaoLink _verificacao(String titulo, StatusVerificacao status) =>
    VerificacaoLink(
      titulo: titulo,
      descricao: 'golpe-exemplo.com.br/entrar',
      fonte: 'Fonte',
      status: status,
    );

ResultadoAnaliseLink _link(List<VerificacaoLink> verificacoes) =>
    ResultadoAnaliseLink(
      score: CalculadoraScore.calcular(const SinaisIdentificados()),
      verificacoes: verificacoes,
    );

void main() {
  final data = DateTime(2026, 11, 3, 10);

  test('do print: leva a faixa pronta, mesmo elevada pela verificação '
      'incompleta', () {
    final score = CalculadoraScore.calcular(
      const SinaisIdentificados(verificacaoIncompleta: true),
    );
    final analise = AnaliseRisco.doPrint(
      AnalisePrintConcluida(
        score: score,
        sinais: const {},
        categoria: CategoriaAmeaca.semIndicios,
        explicacao: 'Explicação.',
        data: data,
      ),
    );

    expect(analise.score, 0);
    expect(analise.faixa, FaixaRisco.medio);
    expect(analise.categoria, CategoriaAmeaca.semIndicios);
    expect(analise.tipoEntrada, TipoEntrada.imagem);
    expect(analise.data, data);
  });

  test('do link: sem categoria, e a explicação usa só os títulos', () {
    final analise = AnaliseRisco.doLink(
      _link([
        _verificacao('Imitação de endereço', StatusVerificacao.sinalEncontrado),
        _verificacao('Lista de perigosos', StatusVerificacao.naoConcluida),
        _verificacao('Tempo de existência', StatusVerificacao.semSinal),
      ]),
      data,
    );

    expect(analise.categoria, isNull);
    expect(analise.tipoEntrada, TipoEntrada.link);
    expect(
      analise.explicacao,
      'Encontramos sinal de risco em: Imitação de endereço. Evite abrir o '
      'link e não informe seus dados nele. Não foi possível concluir: Lista '
      'de perigosos.',
    );
    expect(analise.explicacao, isNot(contains('golpe-exemplo')));
  });

  test('do link sem sinais: não afirma ausência de risco', () {
    final analise = AnaliseRisco.doLink(
      _link([_verificacao('Tempo', StatusVerificacao.semSinal)]),
      data,
    );

    expect(
      analise.explicacao,
      'As verificações concluídas não encontraram sinal de risco.',
    );
  });
}
