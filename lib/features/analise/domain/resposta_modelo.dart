import '../../../shared/domain/categoria_ameaca.dart';
import 'sinal_texto_print.dart';

/// Frase da mensagem que motivou um sinal (RF04; UC04, passo 9). Vem do texto
/// já mascarado e fica só na tela de resultado: não é gravada no histórico.
class TrechoSuspeito {
  const TrechoSuspeito({required this.sinal, required this.texto});

  final SinalTextoPrint sinal;
  final String texto;
}

/// Análise devolvida pelo modelo de linguagem, já validada contra o contrato
/// da Function `analiseTexto` (functions/src/analiseTexto.ts).
///
/// Contém sinais, categoria, explicação e trechos. Não há campo de score: o
/// modelo identifica sinais, e a pontuação é calculada exclusivamente por
/// `CalculadoraScore` (RF07). Um campo extra enviado pelo modelo (ex.:
/// "score") é ignorado, nunca lido.
class RespostaModelo {
  const RespostaModelo({
    required this.sinais,
    required this.categoria,
    required this.explicacao,
    this.trechos = const [],
  });

  final Set<SinalTextoPrint> sinais;
  final CategoriaAmeaca categoria;
  final String explicacao;
  final List<TrechoSuspeito> trechos;

  static const int tamanhoMaximoExplicacao = 2000;
  static const int tamanhoMaximoTrecho = 200;

  /// Códigos trocados com a Function. A correspondência com padrão
  /// catalogado só chega quando a base foi consultada; a Function confere
  /// que o padrão apontado pelo modelo estava entre os recuperados, e o
  /// `AnalisadorPrint` recusa o sinal sem `baseConsultada`.
  static const Map<String, SinalTextoPrint> codigosSinais = {
    'correspondencia_padrao_catalogado':
        SinalTextoPrint.correspondenciaPadraoCatalogado,
    'pedido_financeiro': SinalTextoPrint.pedidoFinanceiro,
    'solicitacao_dados_pessoais': SinalTextoPrint.solicitacaoDadosPessoais,
    'alegacao_troca_contato': SinalTextoPrint.alegacaoTrocaContato,
    'inducao_urgencia': SinalTextoPrint.inducaoUrgencia,
    'ameaca': SinalTextoPrint.ameaca,
    'link_suspeito': SinalTextoPrint.linkSuspeito,
    'oferta_incompativel_mercado': SinalTextoPrint.ofertaIncompativelMercado,
  };

  /// Devolve `null` para qualquer desvio do contrato — campo ausente, tipo
  /// errado, sinal ou categoria desconhecidos, explicação vazia ou longa
  /// demais. Resposta fora do formato é descartada inteira, nunca
  /// aproveitada em parte (UC04, "Resposta inválida do modelo").
  static RespostaModelo? deJson(Object? json) {
    if (json is! Map) return null;

    final sinaisJson = json['sinais'];
    if (sinaisJson is! List) return null;
    final sinais = <SinalTextoPrint>{};
    for (final codigo in sinaisJson) {
      final sinal = codigosSinais[codigo];
      if (sinal == null) return null;
      sinais.add(sinal);
    }

    final categoria = CategoriaAmeaca.doCodigo(json['categoria']);
    if (categoria == null) return null;

    final explicacao = json['explicacao'];
    if (explicacao is! String) return null;
    final explicacaoLimpa = explicacao.trim();
    if (explicacaoLimpa.isEmpty ||
        explicacaoLimpa.length > tamanhoMaximoExplicacao) {
      return null;
    }

    return RespostaModelo(
      sinais: Set.unmodifiable(sinais),
      categoria: categoria,
      explicacao: explicacaoLimpa,
      trechos: _lerTrechos(json['trechos'], sinais),
    );
  }

  /// A Function já confere cada trecho contra o texto. Aqui, um item fora do
  /// formato é ignorado sozinho: sinais e score não dependem do destaque.
  static List<TrechoSuspeito> _lerTrechos(
    Object? json,
    Set<SinalTextoPrint> sinais,
  ) {
    if (json is! List) return const [];
    return List.unmodifiable([
      for (final item in json)
        if (item case {
          'sinal': final Object codigo,
          'trecho': final String texto,
        })
          if (codigosSinais[codigo] case final sinal?
              when sinais.contains(sinal) &&
                  texto.trim().isNotEmpty &&
                  texto.length <= tamanhoMaximoTrecho)
            TrechoSuspeito(sinal: sinal, texto: texto.trim()),
    ]);
  }
}
