import 'package:flutter/material.dart';

import '../../domain/resultado_analise_link.dart';
import '../../domain/resultado_analise_print.dart';
import '../../domain/resultado_score.dart';
import '../../domain/rotulos_risco.dart';
import '../../domain/sinal_texto_print.dart';
import '../../domain/verificacao_link.dart';
import '../widgets/aviso_card.dart';
import '../widgets/o_que_fazer_card.dart';
import '../widgets/termometro_risco.dart';

/// Tela de Resultado da análise de link (RF03, RF07, UC03 passo 8) e de
/// print (RF04, RF07, UC04 passo 9).
///
/// Renderiza inteiramente a partir do resultado recebido — score, faixa e
/// verificações são dado de entrada; a tela não calcula nem ajusta nada.
/// Em particular, a faixa vem pronta de `CalculadoraScore`, que já aplica a
/// regra de verificação incompleta (inclusive a ausência da base de
/// conhecimento na análise de print); a tela nunca a reavalia.
///
/// Termômetro, rotulagem do RF07 e aviso permanente ficam em [build], comuns
/// aos dois tipos; só o detalhamento muda conforme a entrada.
class ResultadoAnalisePage extends StatelessWidget {
  const ResultadoAnalisePage({
    super.key,
    required ResultadoAnaliseLink resultado,
  }) : _link = resultado,
       _print = null;

  /// O resultado de print não contém imagem nem texto analisado
  /// ([AnalisePrintConcluida]): nada da conversa chega a esta tela.
  const ResultadoAnalisePage.print({
    super.key,
    required AnalisePrintConcluida resultado,
  }) : _link = null,
       _print = resultado;

  final ResultadoAnaliseLink? _link;
  final AnalisePrintConcluida? _print;

  ResultadoScore get _score => _link?.score ?? _print!.score;

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final resultadoLink = _link;
    final resultadoPrint = _print;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado da Análise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TermometroRisco(score: score.pontuacao, faixa: score.faixa),
              const SizedBox(height: 20),
              OQueFazerCard(faixa: score.faixa),
              if (resultadoLink != null)
                ..._detalhesLink(context, resultadoLink),
              if (resultadoPrint != null)
                ..._detalhesPrint(context, resultadoPrint),
              const SizedBox(height: 12),
              const AvisoCard(
                key: Key('resultado_aviso_permanente'),
                texto: RotulosRisco.avisoPermanente,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _detalhesLink(
    BuildContext context,
    ResultadoAnaliseLink resultado,
  ) {
    final naoConcluidas = resultado.naoConcluidas;
    return [
      if (naoConcluidas.isNotEmpty) ...[
        const SizedBox(height: 24),
        _AvisoVerificacaoIncompleta(
          texto:
              'Verificação incompleta. Não foi possível concluir: '
              '${naoConcluidas.map((v) => v.titulo).join('; ')}. Enquanto '
              'alguma verificação estiver incompleta, o resultado nunca é '
              'exibido na faixa verde.',
        ),
      ],
      const SizedBox(height: 24),
      Text('O que verificamos', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...resultado.verificacoes.map((v) => _VerificacaoTile(verificacao: v)),
      const SizedBox(height: 24),
      const AvisoCard(
        key: Key('resultado_aviso_falibilidade'),
        texto: RotulosRisco.avisoFalibilidadeReputacao,
      ),
    ];
  }

  List<Widget> _detalhesPrint(
    BuildContext context,
    AnalisePrintConcluida resultado,
  ) {
    final titulo = Theme.of(context).textTheme.titleMedium;
    return [
      if (resultado.verificacoesNaoConcluidas.isNotEmpty) ...[
        const SizedBox(height: 24),
        _AvisoVerificacaoIncompleta(
          texto:
              'Verificação incompleta. '
              '${resultado.verificacoesNaoConcluidas.join(' ')}',
        ),
      ],
      const SizedBox(height: 24),
      Text('O que encontramos na mensagem', style: titulo),
      const SizedBox(height: 8),
      // Sem ícone de confirmação: ausência de sinais conhecidos não é
      // ausência de risco, e com verificação incompleta o texto diz isso.
      if (resultado.sinais.isEmpty)
        ListTile(
          key: const Key('resultado_print_sem_sinais'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.help_outline, color: Colors.orange),
          title: Text(
            resultado.verificacoesNaoConcluidas.isEmpty
                ? 'Não identificamos sinais de golpe conhecidos neste texto.'
                : 'Não identificamos sinais de golpe conhecidos neste texto, '
                      'mas a verificação não pôde ser completa (veja o aviso '
                      'acima).',
          ),
        )
      else
        for (final sinal in SinalTextoPrint.values)
          if (resultado.sinais.contains(sinal))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text(_tituloSinal(sinal)),
            ),
      const SizedBox(height: 16),
      Text('Tipo de abordagem', style: titulo),
      const SizedBox(height: 4),
      Text(
        resultado.categoria.nome,
        key: const Key('resultado_print_categoria'),
      ),
      const SizedBox(height: 16),
      Text('Por que isso importa', style: titulo),
      const SizedBox(height: 4),
      Text(resultado.explicacao, key: const Key('resultado_print_explicacao')),
    ];
  }

  /// Nomes em linguagem não técnica dos sinais do grupo Texto/Print (RF07,
  /// RNF04).
  static String _tituloSinal(SinalTextoPrint sinal) => switch (sinal) {
    SinalTextoPrint.correspondenciaPadraoCatalogado =>
      'Semelhança com golpe já catalogado',
    SinalTextoPrint.pedidoFinanceiro => 'Pedido de dinheiro ou pagamento',
    SinalTextoPrint.alegacaoTrocaContato =>
      'Alegação de troca de número ou de contato',
    SinalTextoPrint.solicitacaoDadosPessoais => 'Pedido de dados pessoais',
    SinalTextoPrint.ameaca => 'Ameaça ou intimidação',
    SinalTextoPrint.linkSuspeito => 'Link suspeito',
    SinalTextoPrint.ofertaIncompativelMercado =>
      'Oferta boa demais para ser verdade',
    SinalTextoPrint.inducaoUrgencia => 'Pressão para agir com urgência',
  };
}

class _AvisoVerificacaoIncompleta extends StatelessWidget {
  const _AvisoVerificacaoIncompleta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('resultado_verificacao_incompleta'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
  }
}

class _VerificacaoTile extends StatelessWidget {
  const _VerificacaoTile({required this.verificacao});

  final VerificacaoLink verificacao;

  @override
  Widget build(BuildContext context) {
    final (icone, situacao) = switch (verificacao.status) {
      StatusVerificacao.sinalEncontrado => (
        const Icon(Icons.flag, color: Colors.red),
        'Sinal de risco encontrado',
      ),
      StatusVerificacao.semSinal => (
        const Icon(Icons.check_circle_outline),
        'Nenhum sinal de risco nesta verificação',
      ),
      StatusVerificacao.naoConcluida => (
        const Icon(Icons.help_outline, color: Colors.orange),
        'Verificação não concluída',
      ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icone,
      title: Text(verificacao.titulo),
      subtitle: Text(
        '$situacao. ${verificacao.descricao}\n'
        'Fonte: ${verificacao.fonte}',
      ),
      isThreeLine: true,
    );
  }
}
