import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/analisador_print.dart';
import '../../domain/exemplo_tutorial_print.dart';
import '../../domain/faixa_risco.dart';
import '../../domain/sinal_texto_print.dart';
import '../widgets/termometro_risco.dart';
import 'cenas_comuns.dart';
import 'etapas_comuns.dart';
import 'tutorial_page.dart';

/// Tutorial da análise de print (RF13), como simulação: a pessoa tira o
/// print de uma conversa desenhada, compartilha com o Phize, vê o que é lido
/// e escondido no próprio celular e lê o resultado. Tudo é fictício e
/// calculado no aparelho: nada vai para a rede nem para o histórico.
class TutorialPrintPage extends StatefulWidget {
  const TutorialPrintPage({super.key});

  @override
  State<TutorialPrintPage> createState() => _TutorialPrintPageState();
}

class _TutorialPrintPageState extends State<TutorialPrintPage> {
  final _tirado = ValueNotifier(false);
  final _exemplo = ValueNotifier(0);

  @override
  void dispose() {
    _tirado.dispose();
    _exemplo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialPage(
      titulo: 'Como analisar um print',
      etapas: [
        EtapaTutorial(
          titulo: 'Tire o print da conversa',
          cena: (_, _) => _CenaTirarPrint(tirado: _tirado),
          explicacao: const ExplicacaoEtapa(
            texto:
                'Abra a conversa e deixe na tela as mensagens que você '
                'recebeu. Tire o print: na maioria dos celulares, aperte ao '
                'mesmo tempo o botão de ligar e o de abaixar o volume.',
            experimente: 'Experimente: toque no botão do celular acima.',
          ),
        ),
        EtapaTutorial(
          titulo: 'Envie ao Phize',
          cena: (_, _) => const _CenaCompartilhar(),
          explicacao: const ExplicacaoEtapa(
            texto:
                'Abra o print na galeria, toque em "Compartilhar" e escolha o '
                'Phize. Ou abra o Phize, toque em "Analisar print" e escolha '
                'o print. Na primeira vez, o Phize explica o que é enviado e '
                'pede a sua autorização.',
            experimente: 'Experimente: toque no Phize.',
          ),
        ),
        EtapaTutorial(
          titulo: 'Seus dados ficam no celular',
          cena: (_, ativa) => _CenaLeitura(ativa: ativa),
          explicacao: const ExplicacaoEtapa(
            texto:
                'O print é lido no próprio celular e apagado em seguida: a '
                'imagem nunca é guardada nem enviada. Só o texto das '
                'mensagens recebidas vai para a análise, com CPF, telefone, '
                'cartão e outros dados trocados por marcadores. Nomes não '
                'são escondidos.',
          ),
        ),
        EtapaTutorial(
          titulo: 'Leia o resultado',
          cena: (_, _) => ValueListenableBuilder(
            valueListenable: _exemplo,
            builder: (_, i, _) =>
                _CenaResultado(exemplo: ExemploTutorialPrint.todos[i]),
          ),
          explicacao: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A inteligência artificial aponta os sinais de golpe no '
                'texto. O número vem de uma regra fixa do Phize, a mesma '
                'para todo mundo.',
              ),
              const SizedBox(height: 12),
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
                        in ExemploTutorialPrint.todos.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OpcaoExemplo(
                          key: Key('tutorial_exemplo_$i'),
                          texto:
                              '${exemplo.contato}: '
                              '"${exemplo.recebidas.first}"',
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

// --- Cenas do celular -----------------------------------------------------

/// Conversa do exemplo principal, com as mensagens recebidas à esquerda e a
/// resposta da pessoa à direita.
class _Conversa extends StatelessWidget {
  const _Conversa();

  @override
  Widget build(BuildContext context) {
    final exemplo = ExemploTutorialPrint.todos.first;
    return ColoredBox(
      color: const Color(0xFFECEFF6),
      // Corta o que não couber, como a tela de um celular de verdade.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mensagem in exemplo.recebidas)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: BalaoRecebido(child: Text(mensagem)),
                ),
              ),
            for (final resposta in exemplo.respostas)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9E2FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Text(resposta),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Etapa 1: a pessoa "tira o print" da conversa.
class _CenaTirarPrint extends StatelessWidget {
  const _CenaTirarPrint({required this.tirado});

  final ValueNotifier<bool> tirado;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: tirado,
      builder: (_, foiTirado, _) => Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BarraCena(
                titulo: ExemploTutorialPrint.todos.first.contato,
                icone: Icons.person,
                cor: CoresPhize.fundoSuave,
              ),
              const Expanded(child: _Conversa()),
            ],
          ),
          // Clarão rápido, como o da captura de tela.
          IgnorePointer(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(foiTirado),
              tween: Tween(begin: foiTirado ? 0.8 : 0, end: 0),
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              builder: (_, opacidade, _) =>
                  ColoredBox(color: Colors.white.withValues(alpha: opacidade)),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: foiTirado
                ? Container(
                    key: const Key('tutorial_print_tirado'),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CoresPhize.tinta,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECEFF6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Print salvo na galeria',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DicaToque(texto: 'Toque para tirar o print'),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: 'Tirar o print',
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: const Key('tutorial_tirar_print'),
                          onTap: () => tirado.value = true,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: CoresPhize.azul,
                                width: 4,
                              ),
                            ),
                            child: const Icon(
                              Icons.screenshot_outlined,
                              color: CoresPhize.azul,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Etapa 2: o print aberto na galeria, com o menu de compartilhar.
class _CenaCompartilhar extends StatelessWidget {
  const _CenaCompartilhar();

  static const _apps = [
    (Icons.chat_bubble_outline, 'SMS'),
    (Icons.mail_outline, 'E-mail'),
    (Icons.folder_outlined, 'Arquivos'),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CoresPhize.tinta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 26),
          // O print, em miniatura, como aparece na galeria.
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                child: IgnorePointer(
                  child: ExcludeSemantics(child: _Conversa()),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Compartilhar com',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (icone, nome) in _apps)
                      Expanded(
                        child: _AppCompartilhar(
                          nome: nome,
                          icone: Icon(icone, color: CoresPhize.textoSecundario),
                          cor: CoresPhize.fundoSuave,
                        ),
                      ),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Compartilhar com o Phize',
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: const Key('tutorial_compartilhar_phize'),
                          onTap: ControleTutorial.of(context).avancar,
                          child: const _AppCompartilhar(
                            nome: 'Phize',
                            icone: Text(
                              'p',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            cor: CoresPhize.azul,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: DicaToque(texto: 'Toque no Phize'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCompartilhar extends StatelessWidget {
  const _AppCompartilhar({
    required this.nome,
    required this.icone,
    required this.cor,
  });

  final String nome;
  final Widget icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          child: icone,
        ),
        const SizedBox(height: 4),
        Text(
          nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

/// Etapa 3: as etapas reais da análise (as mesmas da tela de progresso do
/// app), concluídas uma a uma, e o texto que sairia do celular, já com os
/// dados escondidos pelo mascaramento do app.
class _CenaLeitura extends StatefulWidget {
  const _CenaLeitura({required this.ativa});

  final bool ativa;

  @override
  State<_CenaLeitura> createState() => _CenaLeituraState();
}

class _CenaLeituraState extends State<_CenaLeitura>
    with SingleTickerProviderStateMixin {
  static const _porEtapa = Duration(milliseconds: 800);
  static const _etapas = EtapaAnalisePrint.values;

  late final AnimationController _progresso = AnimationController(
    vsync: this,
    duration: _porEtapa * _etapas.length,
  )..addListener(() => setState(() {}));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _iniciarSeAtiva();
  }

  @override
  void didUpdateWidget(_CenaLeitura antigo) {
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
    final terminou = _progresso.isCompleted;
    final concluidas = terminou
        ? _etapas.length
        : (_progresso.value * _etapas.length).floor();
    final exemplo = ExemploTutorialPrint.todos.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BarraCena(titulo: 'Analisando o print…'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, etapa) in _etapas.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: i < concluidas
                              ? Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: FaixaRisco.baixo.cor,
                                )
                              : const CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(etapa.titulo)),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    child: AnimatedOpacity(
                      // O texto aparece depois de escondidos os dados.
                      opacity: concluidas >= 2 ? 1 : 0,
                      duration: transicaoCena(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'O que sai do celular:',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            key: const Key('tutorial_texto_enviado'),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CoresPhize.fundoSuave,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _TextoComMarcadores(exemplo.textoEnviado),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Não sai: a imagem e a sua resposta '
                            '"${exemplo.respostas.join('", "')}".',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CoresPhize.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: terminou ? 1 : 0,
                  duration: transicaoCena(context),
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

/// Texto com os marcadores do mascaramento (como `[CPF]`) em destaque.
class _TextoComMarcadores extends StatelessWidget {
  const _TextoComMarcadores(this.texto);

  final String texto;

  static final _marcador = RegExp(r'\[[A-Z_]+\]');

  @override
  Widget build(BuildContext context) {
    final partes = <InlineSpan>[];
    var inicio = 0;
    for (final m in _marcador.allMatches(texto)) {
      partes.add(TextSpan(text: texto.substring(inicio, m.start)));
      partes.add(
        TextSpan(
          text: m.group(0),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: CoresPhize.azulEscuro,
            backgroundColor: CoresPhize.azulClaro,
          ),
        ),
      );
      inicio = m.end;
    }
    partes.add(TextSpan(text: texto.substring(inicio)));
    return Text.rich(TextSpan(children: partes));
  }
}

/// Etapa 4: resultado do exemplo escolhido, calculado pelo motor de score.
class _CenaResultado extends StatelessWidget {
  const _CenaResultado({required this.exemplo});

  final ExemploTutorialPrint exemplo;

  @override
  Widget build(BuildContext context) {
    final resultado = exemplo.resultado;
    final sinais = exemplo.sinaisEmOrdem;

    return Column(
      key: const Key('tutorial_resultado_exemplo'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BarraCena(titulo: 'Resultado da Análise'),
        Expanded(
          // Rola dentro do celular, como a tela de resultado do app.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Exemplo fictício: ${exemplo.contato}',
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
                      key: ValueKey(exemplo.contato),
                      tween: IntTween(begin: 0, end: resultado.pontuacao),
                      duration: MediaQuery.of(context).disableAnimations
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
                if (sinais.isEmpty)
                  const Text(
                    'Não identificamos sinais de golpe conhecidos neste texto.',
                    style: TextStyle(fontSize: 11),
                  )
                else
                  for (final sinal in sinais)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: FaixaRisco.alto.cor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sinal.titulo,
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
