import 'package:flutter/material.dart';

/// Aviso de irreversibilidade e confirmação explícita da exclusão (RF12;
/// UC12, passo 4). Devolve a senha digitada, texto vazio para quem confirma
/// pelo Google, ou `null` se cancelado.
class ExcluirContaDialog extends StatefulWidget {
  const ExcluirContaDialog({super.key, this.exigeSenha = true});

  final bool exigeSenha;

  @override
  State<ExcluirContaDialog> createState() => _ExcluirContaDialogState();
}

class _ExcluirContaDialogState extends State<ExcluirContaDialog> {
  final _senhaController = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final senha = _senhaController.text;
    if (widget.exigeSenha && senha.isEmpty) {
      setState(() => _erro = 'Informe sua senha.');
      return;
    }
    Navigator.of(context).pop(senha);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Título e rótulo curtos: com letra muito grande (RF14), palavras
      // longas quebravam no meio e o rótulo do campo ficava cortado.
      title: const Text('Excluir sua conta?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Esta ação não pode ser desfeita. Sua conta e todo o seu '
              'histórico de análises serão apagados, e não será possível '
              'recuperá-los.',
            ),
            if (!widget.exigeSenha) ...[
              const SizedBox(height: 12),
              const Text('Em seguida, confirme com sua conta Google.'),
            ],
            if (widget.exigeSenha) ...[
              const SizedBox(height: 12),
              const Text('Para confirmar, digite sua senha.'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('excluir_conta_senha'),
                controller: _senhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  errorText: _erro,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('excluir_conta_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _confirmar,
          child: const Text('Excluir conta'),
        ),
      ],
    );
  }
}
