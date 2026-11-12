import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/exemplo_tutorial_print.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';

void main() {
  final principal = ExemploTutorialPrint.todos.first;

  test('o resultado é o do motor de score, sem números próprios', () {
    for (final exemplo in ExemploTutorialPrint.todos) {
      final esperado = CalculadoraScore.calcular(
        SinaisIdentificados(textoPrint: exemplo.sinais),
      );
      expect(exemplo.resultado.pontuacao, esperado.pontuacao);
      expect(exemplo.resultado.faixa, esperado.faixa);
    }
  });

  test('o texto enviado esconde telefone e CPF com o mascaramento do app', () {
    expect(principal.textoEnviado, contains('[TELEFONE]'));
    expect(principal.textoEnviado, contains('[CPF]'));
    expect(principal.textoEnviado, isNot(contains('98765-4321')));
    expect(principal.textoEnviado, isNot(contains('123.456.789-09')));
  });

  test('o texto enviado leva só as mensagens recebidas', () {
    for (final resposta in principal.respostas) {
      expect(principal.textoEnviado, isNot(contains(resposta)));
    }
  });

  test('há um exemplo sem sinais, para mostrar a faixa verde', () {
    expect(
      ExemploTutorialPrint.todos.map((e) => e.resultado.faixa),
      contains(FaixaRisco.baixo),
    );
  });

  test('links e nomes de empresa são fictícios', () {
    for (final exemplo in ExemploTutorialPrint.todos) {
      for (final mensagem in exemplo.recebidas) {
        if (mensagem.contains('/')) expect(mensagem, contains('.example'));
      }
    }
  });
}
