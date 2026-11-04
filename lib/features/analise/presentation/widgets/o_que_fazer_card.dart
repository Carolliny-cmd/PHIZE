import 'package:flutter/material.dart';

import '../../domain/faixa_risco.dart';

/// Orientação curta logo abaixo do veredito. O texto é fixo por faixa: não vem
/// do modelo de linguagem, para ser sempre o mesmo e nunca afirmar ausência de
/// risco (CLAUDE.md, Seção 5).
class OQueFazerCard extends StatelessWidget {
  const OQueFazerCard({super.key, required this.faixa});

  final FaixaRisco faixa;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('o_que_fazer'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que fazer agora',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(faixa.oQueFazer),
          ],
        ),
      ),
    );
  }
}
