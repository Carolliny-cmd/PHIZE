import 'package:flutter/material.dart';

import '../../domain/exemplo_tutorial_link.dart';
import '../widgets/o_que_fazer_card.dart';
import '../widgets/termometro_risco.dart';
import 'etapas_comuns.dart';
import 'tutorial_page.dart';

/// Tutorial da análise de link (RF13).
class TutorialLinkPage extends StatelessWidget {
  const TutorialLinkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TutorialPage(
      titulo: 'Como funciona',
      etapas: [
        const EtapaTutorial(
          titulo: 'Onde está o link',
          conteudo: _OndeEstaOLink(),
        ),
        const EtapaTutorial(
          titulo: 'O que o Phize confere',
          conteudo: _OQueConfere(),
        ),
        const EtapaTutorial(
          titulo: 'Experimente com um exemplo',
          conteudo: ExemploInterativoLink(),
        ),
        etapaComoLerResultado(),
      ],
    );
  }
}

class _OndeEstaOLink extends StatelessWidget {
  const _OndeEstaOLink();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ilustração desenhada: uma mensagem com link, sem print real.
        ExcludeSemantics(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: esquema.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Sua encomenda está parada. Acesse '),
                    TextSpan(
                      text: 'entrega-taxa.example/pagar',
                      style: TextStyle(
                        color: esquema.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Link é o endereço de um site que chega por mensagem, SMS ou e-mail. '
          'Costuma aparecer em azul e sublinhado.',
        ),
        const SizedBox(height: 12),
        const _Passo(
          icone: Icons.touch_app_outlined,
          texto: 'Toque e segure o link e escolha "Copiar". Depois, cole na '
              'tela do Phize.',
        ),
        const _Passo(
          icone: Icons.share_outlined,
          texto: 'Ou use o botão "Compartilhar" da mensagem e escolha o Phize.',
        ),
        const _Passo(
          icone: Icons.block_outlined,
          texto: 'Não abra o link antes de analisar.',
        ),
      ],
    );
  }
}

class _OQueConfere extends StatelessWidget {
  const _OQueConfere();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Passo(
          icone: Icons.spellcheck,
          texto: 'Se o endereço imita o nome de um banco ou de uma empresa '
              'conhecida, trocando ou acrescentando letras.',
        ),
        _Passo(
          icone: Icons.calendar_month_outlined,
          texto: 'Há quanto tempo o site existe. Golpes usam sites criados há '
              'poucos dias.',
        ),
        _Passo(
          icone: Icons.gpp_maybe_outlined,
          texto: 'Se o endereço está na lista do Google de sites '
              'possivelmente perigosos.',
        ),
        SizedBox(height: 8),
        Text(
          'O Phize não abre o site: ele confere só o endereço. O link não fica '
          'guardado no seu histórico.',
        ),
      ],
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

/// Exemplo interativo (RF13): a pessoa escolhe um link fictício e vê o
/// resultado calculado pelo motor de score do app, sem rede e sem histórico.
class ExemploInterativoLink extends StatefulWidget {
  const ExemploInterativoLink({super.key});

  @override
  State<ExemploInterativoLink> createState() => _ExemploInterativoLinkState();
}

class _ExemploInterativoLinkState extends State<ExemploInterativoLink> {
  ExemploTutorialLink? _escolhido;
  final _areaResultado = GlobalKey();

  /// Com letra grande, o resultado nasce fora da tela: rola até ele.
  void _escolher(ExemploTutorialLink exemplo) {
    setState(() => _escolhido = exemplo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alvo = _areaResultado.currentContext;
      if (alvo == null || !alvo.mounted) return;
      Scrollable.ensureVisible(
        alvo,
        duration: MediaQuery.of(alvo).disableAnimations
            ? Duration.zero
            : const Duration(milliseconds: 300),
        // Começo do resultado (o termômetro) no topo da área visível.
        alignment: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final escolhido = _escolhido;
    final semAnimacao = MediaQuery.of(context).disableAnimations;
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Toque em um dos links inventados abaixo para ver como o Phize '
          'mostraria o resultado.',
        ),
        const SizedBox(height: 12),
        for (final (i, exemplo) in ExemploTutorialLink.todos.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OpcaoExemplo(
              key: Key('tutorial_exemplo_$i'),
              endereco: exemplo.endereco,
              selecionado: identical(exemplo, escolhido),
              aoTocar: () => _escolher(exemplo),
            ),
          ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          key: _areaResultado,
          duration: semAnimacao
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: escolhido == null
              ? const SizedBox.shrink()
              : _ResultadoExemplo(
                  key: ValueKey(escolhido.endereco),
                  exemplo: escolhido,
                  semAnimacao: semAnimacao,
                  textos: textos,
                ),
        ),
      ],
    );
  }
}

/// Opção de exemplo que quebra linha com letra grande, em vez de cortar o
/// endereço.
class _OpcaoExemplo extends StatelessWidget {
  const _OpcaoExemplo({
    super.key,
    required this.endereco,
    required this.selecionado,
    required this.aoTocar,
  });

  final String endereco;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selecionado ? esquema.primary : esquema.outline,
        width: selecionado ? 2 : 1,
      ),
    );
    return Semantics(
      button: true,
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      child: Material(
        shape: forma,
        color: selecionado ? esquema.secondaryContainer : esquema.surface,
        child: InkWell(
          customBorder: forma,
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selecionado
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: esquema.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(endereco)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultadoExemplo extends StatelessWidget {
  const _ResultadoExemplo({
    super.key,
    required this.exemplo,
    required this.semAnimacao,
    required this.textos,
  });

  final ExemploTutorialLink exemplo;
  final bool semAnimacao;
  final TextTheme textos;

  @override
  Widget build(BuildContext context) {
    final resultado = exemplo.resultado;
    return Card(
      key: const Key('tutorial_resultado_exemplo'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Exemplo fictício',
              style: textos.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // O número sobe até o valor calculado; sem animação quando a
            // redução de movimento está ligada.
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: resultado.pontuacao),
              duration: semAnimacao
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              builder: (_, valor, _) =>
                  TermometroRisco(score: valor, faixa: resultado.faixa),
            ),
            const SizedBox(height: 12),
            for (final verificacao in exemplo.verificacoes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      verificacao.encontrado
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      semanticLabel: verificacao.encontrado
                          ? 'Sinal encontrado'
                          : 'Nenhum sinal',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        verificacao.texto,
                        key: Key(
                          'tutorial_verificacao_${verificacao.sinal.name}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            OQueFazerCard(faixa: resultado.faixa),
          ],
        ),
      ),
    );
  }
}
