import 'calculadora_score.dart';
import 'resultado_score.dart';
import 'sinais_identificados.dart';
import 'sinal_link.dart';

/// Exemplo fictício do tutorial da análise de link (RF13).
///
/// O resultado sai de [CalculadoraScore], a mesma função do app, a partir
/// de sinais fixos: nada é consultado na rede nem gravado no histórico, e
/// nenhum peso ou ponto de corte é repetido aqui (fonte única:
/// `docs/score-calibracao.md`). Os endereços usam o domínio reservado
/// `.example` e uma loja inventada, "Loja Feliz".
class ExemploTutorialLink {
  const ExemploTutorialLink({required this.endereco, required this.sinais});

  final String endereco;
  final Set<SinalLink> sinais;

  ResultadoScore get resultado =>
      CalculadoraScore.calcular(SinaisIdentificados(link: sinais));

  /// As três verificações do link, na ordem da tela de resultado, com o
  /// que o exemplo encontrou em cada uma.
  List<VerificacaoExemplo> get verificacoes => [
    for (final sinal in SinalLink.values)
      VerificacaoExemplo(
        sinal: sinal,
        encontrado: sinais.contains(sinal),
      ),
  ];

  static const List<ExemploTutorialLink> todos = [
    ExemploTutorialLink(
      endereco: 'loja-fe1iz.example/promocao',
      sinais: {SinalLink.typosquatting, SinalLink.dominioRecemCriado},
    ),
    ExemploTutorialLink(
      endereco: 'entrega-taxa.example/pagar',
      sinais: {SinalLink.listadoSafeBrowsing},
    ),
    ExemploTutorialLink(endereco: 'lojafeliz.example', sinais: {}),
  ];
}

/// Uma verificação do exemplo, em linguagem simples.
class VerificacaoExemplo {
  const VerificacaoExemplo({required this.sinal, required this.encontrado});

  final SinalLink sinal;
  final bool encontrado;

  String get texto => switch ((sinal, encontrado)) {
    (SinalLink.typosquatting, true) =>
      'Imita o nome da Loja Feliz, trocando o "l" pelo número "1".',
    (SinalLink.typosquatting, false) =>
      'Não imita o nome de nenhuma empresa da nossa lista.',
    (SinalLink.dominioRecemCriado, true) =>
      'O site foi criado há poucos dias. Golpes usam endereços novos.',
    (SinalLink.dominioRecemCriado, false) => 'O site existe há anos.',
    (SinalLink.listadoSafeBrowsing, true) =>
      'Está na lista do Google de sites possivelmente perigosos.',
    (SinalLink.listadoSafeBrowsing, false) =>
      'Não está na lista do Google de sites perigosos.',
  };
}
