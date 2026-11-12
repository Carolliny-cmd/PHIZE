import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/exemplo_tutorial_link.dart';
import '../../domain/faixa_risco.dart';
import '../widgets/termometro_risco.dart';
import 'etapas_comuns.dart';
import 'tutorial_page.dart';

/// Tutorial da análise de link (RF13), como simulação: a pessoa copia o link
/// numa conversa desenhada, cola no Phize, acompanha as verificações e lê o
/// resultado. Tudo é fictício e calculado no aparelho: nada vai para a rede
/// nem para o histórico.
class TutorialLinkPage extends StatefulWidget {
  const TutorialLinkPage({super.key});

  @override
  State<TutorialLinkPage> createState() => _TutorialLinkPageState();
}

class _TutorialLinkPageState extends State<TutorialLinkPage> {
  final _copiado = ValueNotifier(false);
  final _colado = ValueNotifier(false);
  final _exemplo = ValueNotifier(0);

  @override
  void dispose() {
    _copiado.dispose();
    _colado.dispose();
    _exemplo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialPage(
      titulo: 'Como analisar um link',
      etapas: [
        EtapaTutorial(
          titulo: 'Copie o link, sem abrir',
          cena: (_, _) => _CenaConversa(copiado: _copiado),
          explicacao: const _Explicacao(
            texto:
                'Recebeu um link estranho por mensagem, SMS ou e-mail? Não '
                'toque para abrir. Toque e segure o link e escolha "Copiar".',
            experimente: 'Experimente: toque e segure o link no celular acima.',
          ),
        ),
        EtapaTutorial(
          titulo: 'Cole no Phize',
          cena: (_, _) => _CenaColar(colado: _colado),
          explicacao: const _Explicacao(
            texto:
                'No Phize, toque em "Analisar link", cole o endereço e '
                'toque em "Verificar link". Você também pode usar o botão '
                '"Compartilhar" da mensagem e escolher o Phize.',
            experimente:
                'Experimente: toque em "Colar" e depois em '
                '"Verificar link".',
          ),
        ),
        EtapaTutorial(
          titulo: 'O Phize confere o endereço',
          cena: (_, ativa) => _CenaVerificacoes(ativa: ativa),
          explicacao: const _Explicacao(
            texto:
                'São três verificações: se o nome imita uma empresa '
                'conhecida, há quanto tempo o site existe e se ele está na '
                'lista do Google de sites perigosos. O Phize não abre o site, '
                'e o link não fica guardado no seu histórico.',
          ),
        ),
        EtapaTutorial(
          titulo: 'Leia o resultado',
          cena: (_, _) => ValueListenableBuilder(
            valueListenable: _exemplo,
            builder: (_, i, _) =>
                _CenaResultado(exemplo: ExemploTutorialLink.todos[i]),
          ),
          explicacao: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ComoLerResultado(),
              const SizedBox(height: 16),
              Text(
                'Veja outros exemplos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: _exemplo,
                builder: (_, escolhido, _) => Column(
                  children: [
                    for (final (i, exemplo)
                        in ExemploTutorialLink.todos.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _OpcaoExemplo(
                          key: Key('tutorial_exemplo_$i'),
                          endereco: exemplo.endereco,
                          selecionado: i == escolhido,
                          aoTocar: () => _exemplo.value = i,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Explicacao extends StatelessWidget {
  const _Explicacao({required this.texto, this.experimente});

  final String texto;
  final String? experimente;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(texto),
        if (experimente != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.touch_app_outlined, color: CoresPhize.azul),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  experimente!,
                  style: const TextStyle(
                    color: CoresPhize.azulEscuro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// --- Cenas do celular -----------------------------------------------------

/// Transição curta das cenas; nenhuma com a redução de movimento ligada.
Duration _transicao(BuildContext context) =>
    MediaQuery.of(context).disableAnimations
    ? Duration.zero
    : const Duration(milliseconds: 200);

/// Barra superior das telas simuladas.
class _BarraCena extends StatelessWidget {
  const _BarraCena({required this.titulo, this.icone, this.cor});

  final String titulo;
  final IconData? icone;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cor ?? Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 10),
      child: Row(
        children: [
          if (icone != null) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: CoresPhize.borda,
              child: Icon(icone, size: 16, color: CoresPhize.textoSecundario),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etapa 1: conversa com um link fictício, que a pessoa copia.
class _CenaConversa extends StatelessWidget {
  const _CenaConversa({required this.copiado});

  final ValueNotifier<bool> copiado;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: copiado,
      builder: (_, foiCopiado, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BarraCena(
            titulo: 'Número desconhecido',
            icone: Icons.person,
            cor: CoresPhize.fundoSuave,
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFECEFF6),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _Balao(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sua encomenda está parada. Pague a taxa de '
                                'liberação em:',
                              ),
                              const SizedBox(height: 4),
                              Semantics(
                                button: true,
                                label:
                                    'Link da mensagem. Toque e segure para '
                                    'copiar',
                                child: GestureDetector(
                                  key: const Key('tutorial_chat_link'),
                                  onLongPress: () => copiado.value = true,
                                  onTap: () => copiado.value = true,
                                  child: AnimatedContainer(
                                    duration: _transicao(context),
                                    padding: const EdgeInsets.all(2),
                                    color: foiCopiado
                                        ? CoresPhize.azulClaro
                                        : Colors.transparent,
                                    child: Text(
                                      ExemploTutorialLink.todos.first.endereco,
                                      style: const TextStyle(
                                        color: CoresPhize.azul,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!foiCopiado)
                    const Positioned(
                      top: 12,
                      left: 14,
                      right: 14,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DicaToque(texto: 'Toque e segure o link'),
                      ),
                    ),
                  if (foiCopiado)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 20,
                      child: Center(
                        child: Container(
                          key: const Key('tutorial_link_copiado'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: CoresPhize.tinta,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Link copiado',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: child,
    );
  }
}

/// Etapa 2: tela "Analisar link" simulada, onde a pessoa cola e verifica.
class _CenaColar extends StatelessWidget {
  const _CenaColar({required this.colado});

  final ValueNotifier<bool> colado;

  @override
  Widget build(BuildContext context) {
    final semAnimacao = MediaQuery.of(context).disableAnimations;
    final endereco = ExemploTutorialLink.todos.first.endereco;

    return ValueListenableBuilder(
      valueListenable: colado,
      builder: (_, foiColado, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BarraCena(titulo: 'Analisar link'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Cole abaixo o link que você recebeu.'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: CoresPhize.fundoSuave,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: foiColado ? CoresPhize.azul : CoresPhize.borda,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: foiColado
                              // O endereço aparece letra por letra.
                              ? TweenAnimationBuilder<int>(
                                  tween: IntTween(
                                    begin: 0,
                                    end: endereco.length,
                                  ),
                                  duration: semAnimacao
                                      ? Duration.zero
                                      : const Duration(milliseconds: 500),
                                  builder: (_, n, _) => Text(
                                    endereco.substring(0, n),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const Text(
                                  'https://...',
                                  style: TextStyle(
                                    color: CoresPhize.textoSecundario,
                                  ),
                                ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Colar o link',
                          excludeSemantics: true,
                          child: GestureDetector(
                            key: const Key('tutorial_colar'),
                            onTap: () => colado.value = true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: CoresPhize.azulClaro,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Colar',
                                style: TextStyle(
                                  color: CoresPhize.azulEscuro,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    enabled: foiColado,
                    label: 'Verificar link',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const Key('tutorial_verificar'),
                      onTap: foiColado
                          ? ControleTutorial.of(context).avancar
                          : null,
                      child: AnimatedContainer(
                        duration: _transicao(context),
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: foiColado ? CoresPhize.azul : CoresPhize.borda,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verificar link',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DicaToque(
                      key: ValueKey(foiColado),
                      texto: foiColado
                          ? 'Toque em "Verificar link"'
                          : 'Toque em "Colar"',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etapa 3: as três verificações, concluídas uma a uma quando a etapa
/// aparece. O resultado de cada uma é o do exemplo fictício.
class _CenaVerificacoes extends StatefulWidget {
  const _CenaVerificacoes({required this.ativa});

  final bool ativa;

  @override
  State<_CenaVerificacoes> createState() => _CenaVerificacoesState();
}

class _CenaVerificacoesState extends State<_CenaVerificacoes>
    with SingleTickerProviderStateMixin {
  static const _porVerificacao = Duration(milliseconds: 700);

  late final _verificacoes = ExemploTutorialLink.todos.first.verificacoes;
  late final AnimationController _progresso = AnimationController(
    vsync: this,
    duration: _porVerificacao * _verificacoes.length,
  )..addListener(() => setState(() {}));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _iniciarSeAtiva();
  }

  @override
  void didUpdateWidget(_CenaVerificacoes antigo) {
    super.didUpdateWidget(antigo);
    _iniciarSeAtiva();
  }

  void _iniciarSeAtiva() {
    if (!widget.ativa || _progresso.value > 0 || _progresso.isAnimating) {
      return;
    }
    if (MediaQuery.of(context).disableAnimations) {
      _progresso.value = 1;
    } else {
      _progresso.forward();
    }
  }

  @override
  void dispose() {
    _progresso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final concluidas = (_progresso.value * _verificacoes.length).floor();
    final terminou = _progresso.isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BarraCena(titulo: 'Analisando o link…'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ExemploTutorialLink.todos.first.endereco,
                  style: const TextStyle(color: CoresPhize.textoSecundario),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, v) in _verificacoes.indexed)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CoresPhize.fundoSuave,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: i < concluidas || terminou
                                      ? Icon(
                                          v.encontrado
                                              ? Icons.warning_amber_rounded
                                              : Icons.check_circle,
                                          size: 18,
                                          color: v.encontrado
                                              ? FaixaRisco.alto.cor
                                              : FaixaRisco.baixo.cor,
                                        )
                                      : const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (i < concluidas || terminou)
                                        Text(
                                          v.texto,
                                          key: Key(
                                            'tutorial_verificacao_${v.sinal.name}',
                                          ),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: terminou ? 1 : 0,
                  duration: _transicao(context),
                  child: Semantics(
                    button: true,
                    label: 'Ver resultado',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const Key('tutorial_ver_resultado'),
                      onTap: terminou
                          ? ControleTutorial.of(context).avancar
                          : null,
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CoresPhize.azul,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Ver resultado',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Etapa 4: resultado do exemplo escolhido, calculado pelo motor de score.
class _CenaResultado extends StatelessWidget {
  const _CenaResultado({required this.exemplo});

  final ExemploTutorialLink exemplo;

  @override
  Widget build(BuildContext context) {
    final resultado = exemplo.resultado;
    final semAnimacao = MediaQuery.of(context).disableAnimations;

    return Column(
      key: const Key('tutorial_resultado_exemplo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BarraCena(titulo: 'Resultado da Análise'),
        Expanded(
          // Rola dentro do celular, como a tela de resultado do app.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Exemplo fictício: ${exemplo.endereco}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: CoresPhize.textoSecundario,
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: FittedBox(
                    // O número sobe até o valor calculado.
                    child: TweenAnimationBuilder<int>(
                      key: ValueKey(exemplo.endereco),
                      tween: IntTween(begin: 0, end: resultado.pontuacao),
                      duration: semAnimacao
                          ? Duration.zero
                          : const Duration(milliseconds: 700),
                      builder: (_, valor, _) => SizedBox(
                        width: 260,
                        child: TermometroRisco(
                          score: valor,
                          faixa: resultado.faixa,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                for (final v in exemplo.verificacoes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          v.encontrado
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 14,
                          color: v.encontrado
                              ? FaixaRisco.alto.cor
                              : FaixaRisco.baixo.cor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            v.texto,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CoresPhize.fundoSuave,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'O que fazer agora',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        resultado.faixa.oQueFazer,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selecionado ? CoresPhize.azul : CoresPhize.borda,
        width: selecionado ? 2 : 1,
      ),
    );
    return Semantics(
      button: true,
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      child: Material(
        shape: forma,
        color: selecionado ? CoresPhize.azulClaro : Colors.white,
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
                  color: CoresPhize.azul,
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
