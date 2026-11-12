import 'package:flutter/material.dart';

/// Escolha de uma opção entre poucas, como o tamanho da letra e o tema
/// (RF14). Tocar numa opção já fecha e devolve o valor; fechar sem tocar
/// devolve `null`.
class EscolhaDialog<T> extends StatelessWidget {
  const EscolhaDialog({
    super.key,
    required this.titulo,
    required this.opcoes,
    required this.atual,
    required this.rotulo,
    this.chave,
  });

  final String titulo;
  final List<T> opcoes;
  final T atual;
  final String Function(T) rotulo;

  /// Chave de teste de cada opção.
  final String Function(T)? chave;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: RadioGroup<T>(
        groupValue: atual,
        onChanged: (valor) => Navigator.of(context).pop(valor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opcao in opcoes)
              RadioListTile<T>(
                key: chave == null ? null : Key(chave!(opcao)),
                value: opcao,
                title: Text(rotulo(opcao)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
