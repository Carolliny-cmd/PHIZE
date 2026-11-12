import 'package:flutter/material.dart';

import '../../domain/faixa_risco.dart';
import '../../domain/rotulos_risco.dart';
import '../widgets/aviso_card.dart';
import 'tutorial_page.dart';

/// Etapa "Como ler o resultado", comum aos tutoriais de link e de print
/// (RF13). Os rótulos vêm de [RotulosRisco], fonte única do RF07.
EtapaTutorial etapaComoLerResultado() => const EtapaTutorial(
  titulo: 'Como ler o resultado',
  conteudo: _ComoLerResultado(),
);

class _ComoLerResultado extends StatelessWidget {
  const _ComoLerResultado();

  static const Map<FaixaRisco, String> _significado = {
    FaixaRisco.baixo:
        'Não achamos sinais de golpe. Isso não garante que não haja risco.',
    FaixaRisco.medio:
        'Achamos algo estranho. Não pague nem envie dados antes de confirmar.',
    FaixaRisco.alto:
        'Achamos vários sinais de golpe. Não envie dinheiro nem dados.',
  };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'O resultado vem em uma de três cores, com um número de 0 a 100. '
          'Quanto maior o número, mais sinais de golpe.',
        ),
        const SizedBox(height: 16),
        for (final faixa in FaixaRisco.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ExcludeSemantics(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: faixa.cor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faixa.rotulo,
                        style: textos.titleMedium?.copyWith(
                          color: faixa.corTexto,
                        ),
                      ),
                      Text(_significado[faixa]!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Text(
          'Se alguma verificação não puder ser feita, o resultado nunca fica '
          'verde, e a tela diz qual verificação faltou.',
        ),
        const SizedBox(height: 16),
        const AvisoCard(texto: RotulosRisco.avisoPermanente),
      ],
    );
  }
}
