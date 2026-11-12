import 'package:flutter/material.dart';

import '../../domain/tutorial_repository.dart';

/// Uma etapa do tutorial (RF13): título e conteúdo livre.
class EtapaTutorial {
  const EtapaTutorial({required this.titulo, required this.conteudo});

  final String titulo;
  final Widget conteudo;
}

/// Tela de tutorial em etapas (RF13): no máximo 4, com indicador de
/// progresso, Voltar, Próximo e Pular. Com a redução de movimento do
/// sistema ligada, a troca de etapa acontece sem animação.
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, required this.titulo, required this.etapas})
    : assert(etapas.length > 0 && etapas.length <= 4);

  final String titulo;
  final List<EtapaTutorial> etapas;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final _paginas = PageController();
  int _atual = 0;

  bool get _ultima => _atual == widget.etapas.length - 1;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _irPara(int etapa) {
    if (MediaQuery.of(context).disableAnimations) {
      _paginas.jumpToPage(etapa);
    } else {
      _paginas.animateToPage(
        etapa,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _fechar() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final total = widget.etapas.length;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.titulo),
        actions: [
          TextButton(
            key: const Key('tutorial_pular'),
            onPressed: _fechar,
            child: const Text('Pular'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _paginas,
                onPageChanged: (etapa) => setState(() => _atual = etapa),
                children: [
                  for (final etapa in widget.etapas)
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              etapa.titulo,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 16),
                          etapa.conteudo,
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: 'Etapa ${_atual + 1} de $total',
              excludeSemantics: true,
              child: Row(
                key: const Key('tutorial_progresso'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < total; i++)
                    AnimatedContainer(
                      duration: MediaQuery.of(context).disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _atual ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == _atual ? esquema.primary : esquema.outline,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  if (_atual > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('tutorial_voltar'),
                        onPressed: () => _irPara(_atual - 1),
                        child: const Text('Voltar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      key: const Key('tutorial_proximo'),
                      onPressed: _ultima ? _fechar : () => _irPara(_atual + 1),
                      child: Text(_ultima ? 'Começar' : 'Próximo'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre o tutorial e, ao fechá-lo por qualquer caminho (concluir, pular ou
/// voltar), grava a marca de visto. Falha ao gravar não impede a análise.
Future<void> abrirTutorial(
  BuildContext context, {
  required TipoTutorial tipo,
  required TutorialRepository repositorio,
  required WidgetBuilder construir,
}) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: construir));
  try {
    await repositorio.marcarVisto(tipo);
  } catch (_) {
    // Sem a marca, o tutorial só aparece de novo na próxima abertura.
  }
}

/// Abre o tutorial só se ele ainda não foi visto nesta versão. Se a marca
/// não puder ser lida, não abre: o tutorial nunca bloqueia a análise.
Future<void> abrirTutorialNaPrimeiraVez(
  BuildContext context, {
  required TipoTutorial tipo,
  required TutorialRepository repositorio,
  required WidgetBuilder construir,
}) async {
  final bool visto;
  try {
    visto = await repositorio.visto(tipo);
  } catch (_) {
    return;
  }
  if (visto || !context.mounted) return;
  await abrirTutorial(
    context,
    tipo: tipo,
    repositorio: repositorio,
    construir: construir,
  );
}
