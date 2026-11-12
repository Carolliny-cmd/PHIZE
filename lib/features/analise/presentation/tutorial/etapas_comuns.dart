import 'package:flutter/material.dart';

import '../../domain/faixa_risco.dart';
import '../../domain/rotulos_risco.dart';
import '../widgets/aviso_card.dart';

/// "Como ler o resultado", comum aos tutoriais de link e de print (RF13).
/// Os rótulos vêm de [RotulosRisco], fonte única do RF07.
class ComoLerResultado extends StatelessWidget {
  const ComoLerResultado({super.key});

  static const Map<FaixaRisco, String> _significado = {
    FaixaRisco.baixo: 'Isso não garante que não haja risco.',
    FaixaRisco.medio: 'Não pague nem envie dados antes de confirmar.',
    FaixaRisco.alto: 'Não envie dinheiro nem dados.',
  };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'O número vai de 0 a 100: quanto maior, mais sinais de golpe. A cor '
          'resume o resultado:',
        ),
        const SizedBox(height: 12),
        for (final faixa in FaixaRisco.values)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: faixa.cor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: faixa.cor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faixa.rotulo,
                  style: textos.titleMedium?.copyWith(color: faixa.corTexto),
                ),
                Text(_significado[faixa]!),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'Se alguma verificação não puder ser feita, o resultado nunca fica '
          'verde, e a tela diz qual verificação faltou.',
        ),
        const SizedBox(height: 12),
        const AvisoCard(texto: RotulosRisco.avisoPermanente),
      ],
    );
  }
}
