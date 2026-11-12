import 'calculadora_score.dart';
import 'mascaramento_local.dart';
import 'resultado_score.dart';
import 'sinais_identificados.dart';
import 'sinal_texto_print.dart';

/// Exemplo fictício do tutorial da análise de print (RF13).
///
/// As mensagens são inventadas, com números que não pertencem a ninguém.
/// O texto que "seria enviado" passa pelo mascaramento real do app
/// ([mascararTextoLocal]) e reúne só as mensagens recebidas, como faz a
/// organização do texto do print. Os sinais são fixos, porque no app quem
/// os aponta é o modelo de linguagem; o número sai de [CalculadoraScore],
/// sem pesos repetidos aqui (fonte única: `docs/score-calibracao.md`).
/// Nada é enviado à rede nem gravado no histórico.
class ExemploTutorialPrint {
  const ExemploTutorialPrint({
    required this.contato,
    required this.recebidas,
    this.respostas = const [],
    required this.sinais,
  });

  final String contato;

  /// Mensagens recebidas, na ordem da conversa.
  final List<String> recebidas;

  /// Respostas da própria pessoa, que não são enviadas para a análise.
  final List<String> respostas;

  final Set<SinalTextoPrint> sinais;

  /// O texto que o app enviaria: só as recebidas, já mascaradas.
  String get textoEnviado => mascararTextoLocal(recebidas.join('\n'));

  ResultadoScore get resultado =>
      CalculadoraScore.calcular(SinaisIdentificados(textoPrint: sinais));

  /// Sinais encontrados, na ordem da tela de resultado.
  List<SinalTextoPrint> get sinaisEmOrdem => [
    for (final sinal in SinalTextoPrint.values)
      if (sinais.contains(sinal)) sinal,
  ];

  /// O primeiro é o da simulação passo a passo; os outros podem ser
  /// escolhidos na última etapa.
  static const List<ExemploTutorialPrint> todos = [
    ExemploTutorialPrint(
      contato: 'Número desconhecido',
      recebidas: [
        'Oi mãe, troquei de número. Salva esse: (41) 98765-4321',
        'Preciso pagar um boleto hoje, me faz um Pix? Chave: 123.456.789-09',
      ],
      respostas: ['Quem é?'],
      sinais: {
        SinalTextoPrint.correspondenciaPadraoCatalogado,
        SinalTextoPrint.alegacaoTrocaContato,
        SinalTextoPrint.pedidoFinanceiro,
        SinalTextoPrint.inducaoUrgencia,
      },
    ),
    ExemploTutorialPrint(
      contato: 'Banco Exemplo',
      recebidas: [
        'Sua conta será bloqueada hoje.',
        'Confirme seus dados em banco-exemplo.example/atualizar',
      ],
      sinais: {
        SinalTextoPrint.solicitacaoDadosPessoais,
        SinalTextoPrint.linkSuspeito,
        SinalTextoPrint.inducaoUrgencia,
      },
    ),
    ExemploTutorialPrint(
      contato: 'Clínica Exemplo',
      recebidas: ['Sua consulta está confirmada para amanhã, às 9h.'],
      respostas: ['Obrigada!'],
      sinais: {},
    ),
  ];
}
