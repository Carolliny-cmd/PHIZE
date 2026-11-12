import 'package:flutter/material.dart';

import '../../domain/nome_exibicao.dart';

/// Resposta do [EditarNomeDialog]: o nome normalizado, ou `null` para
/// remover o nome.
class NomeEditado {
  const NomeEditado(this.nome);

  final String? nome;
}

/// Edição do nome de exibição (RF14). Devolve `null` ao cancelar.
class EditarNomeDialog extends StatefulWidget {
  const EditarNomeDialog({super.key, required this.nomeAtual});

  final String? nomeAtual;

  @override
  State<EditarNomeDialog> createState() => _EditarNomeDialogState();
}

class _EditarNomeDialogState extends State<EditarNomeDialog> {
  late final _campo = TextEditingController(text: widget.nomeAtual ?? '');
  String? _erro;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  void _salvar() {
    final erro = validarNomeExibicao(_campo.text);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop(NomeEditado(normalizarNomeExibicao(_campo.text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nome de exibição'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Opcional. Pode ser um apelido: o Phize não confere se é o seu '
            'nome real.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('editar_nome_campo'),
            controller: _campo,
            autofocus: true,
            maxLength: limiteNomeExibicao,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nome ou apelido',
              errorText: _erro,
            ),
            onSubmitted: (_) => _salvar(),
          ),
        ],
      ),
      actions: [
        if (widget.nomeAtual != null)
          TextButton(
            key: const Key('editar_nome_remover'),
            onPressed: () => Navigator.of(context).pop(const NomeEditado(null)),
            child: const Text('Remover'),
          ),
        TextButton(
          key: const Key('editar_nome_cancelar'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('editar_nome_salvar'),
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
