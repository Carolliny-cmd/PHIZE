import '../../../shared/domain/categoria_ameaca.dart';
import 'faixa_risco.dart';
import 'resultado_analise_link.dart';
import 'resultado_analise_print.dart';
import 'verificacao_link.dart';

/// Registro de uma análise no Histórico (UC06): apenas o resultado, nunca o
/// conteúdo analisado (RNF01, RNF07 etapa 4; arquitetura, 5.4).
///
/// A faixa é gravada, e não recalculada do score, porque a regra de
/// verificação incompleta pode exibir em amarelo uma pontuação que sozinha
/// seria verde (RF07): o histórico mostra o veredito que a pessoa viu.
class AnaliseRisco {
  const AnaliseRisco({
    this.id,
    required this.score,
    required this.faixa,
    required this.categoria,
    required this.explicacao,
    required this.tipoEntrada,
    required this.data,
  });

  factory AnaliseRisco.doPrint(AnalisePrintConcluida resultado) => AnaliseRisco(
    score: resultado.score.pontuacao,
    faixa: resultado.score.faixa,
    categoria: resultado.categoria,
    explicacao: resultado.explicacao,
    tipoEntrada: resultado.tipoEntrada,
    data: resultado.data,
  );

  /// A análise de link não tem categoria de ameaça (`docs/categorias-ameaca.md`
  /// cobre só o print). A explicação usa apenas os títulos fixos das
  /// verificações: o endereço analisado nunca entra no registro (UC03,
  /// pós-condições).
  factory AnaliseRisco.doLink(ResultadoAnaliseLink resultado, DateTime data) =>
      AnaliseRisco(
        score: resultado.score.pontuacao,
        faixa: resultado.score.faixa,
        categoria: null,
        explicacao: _explicacaoLink(resultado),
        tipoEntrada: TipoEntrada.link,
        data: data,
      );

  /// Atribuído pelo banco; nulo enquanto o registro não foi gravado.
  final String? id;
  final int score;
  final FaixaRisco faixa;

  /// Nula nas análises de link.
  final CategoriaAmeaca? categoria;
  final String explicacao;
  final TipoEntrada tipoEntrada;
  final DateTime data;

  static String _explicacaoLink(ResultadoAnaliseLink resultado) {
    final comSinal = resultado.verificacoes
        .where((v) => v.status == StatusVerificacao.sinalEncontrado)
        .map((v) => v.titulo);
    final naoConcluidas = resultado.naoConcluidas.map((v) => v.titulo);

    return [
      if (comSinal.isEmpty)
        'As verificações concluídas não encontraram sinal de risco.'
      else ...[
        'Encontramos sinal de risco em: ${comSinal.join('; ')}.',
        'Evite abrir o link e não informe seus dados nele.',
      ],
      if (naoConcluidas.isNotEmpty)
        'Não foi possível concluir: ${naoConcluidas.join('; ')}.',
    ].join(' ');
  }
}
