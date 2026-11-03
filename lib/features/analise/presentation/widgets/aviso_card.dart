import 'package:flutter/material.dart';

/// Cartão de aviso informativo das telas de resultado e histórico.
class AvisoCard extends StatelessWidget {
  const AvisoCard({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
  }
}
