import 'package:flutter/material.dart';

import '../../../auth/domain/auth_exception.dart';
import '../../../auth/domain/auth_validators.dart';

/// Troca de senha (RF14): senha atual, nova senha com a regra do RF01 e
/// confirmação. Fica aberto até a troca dar certo, para mostrar o erro
/// junto dos campos. Devolve `true` depois da troca.
class TrocarSenhaDialog extends StatefulWidget {
  const TrocarSenhaDialog({super.key, required this.trocar});

  /// Lança `AuthException` com a mensagem para a pessoa.
  final Future<void> Function(String senhaAtual, String novaSenha) trocar;

  static const String mensagemFalha =
      'Não foi possível trocar a senha. Verifique sua conexão e tente '
      'novamente.';

  @override
  State<TrocarSenhaDialog> createState() => _TrocarSenhaDialogState();
}

class _TrocarSenhaDialogState extends State<TrocarSenhaDialog> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();
  String? _erroAtual;
  String? _erroNova;
  String? _erroConfirmacao;
  String? _erro;
  bool _enviando = false;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final atual = _atual.text;
    final nova = _nova.text;
    setState(() {
      _erro = null;
      _erroAtual = atual.isEmpty ? 'Informe sua senha atual.' : null;
      _erroNova =
          validarSenha(nova) ??
          (nova == atual ? 'A nova senha precisa ser diferente da atual.' : null);
      _erroConfirmacao = _confirmacao.text == nova
          ? null
          : 'As senhas não conferem.';
    });
    if (_erroAtual != null || _erroNova != null || _erroConfirmacao != null) {
      return;
    }

    setState(() => _enviando = true);
    try {
      await widget.trocar(atual, nova);
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = e.mensagem;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = TrocarSenhaDialog.mensagemFalha;
        });
      }
    }
  }

  Widget _campo({
    required Key key,
    required TextEditingController controle,
    required String rotulo,
    required String? erro,
    required List<String> preenchimento,
    TextInputAction acao = TextInputAction.next,
    ValueChanged<String>? aoEnviar,
  }) {
    return TextField(
      key: key,
      controller: controle,
      enabled: !_enviando,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: preenchimento,
      textInputAction: acao,
      onSubmitted: aoEnviar,
      decoration: InputDecoration(labelText: rotulo, errorText: erro),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erro = _erro;
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: const Text('Trocar senha'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Para sua segurança, confirme a senha atual. A nova precisa ter '
              'pelo menos 8 caracteres.',
            ),
            const SizedBox(height: 16),
            _campo(
              key: const Key('trocar_senha_atual'),
              controle: _atual,
              rotulo: 'Senha atual',
              erro: _erroAtual,
              preenchimento: const [AutofillHints.password],
            ),
            const SizedBox(height: 12),
            _campo(
              key: const Key('trocar_senha_nova'),
              controle: _nova,
              rotulo: 'Nova senha',
              erro: _erroNova,
              preenchimento: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),
            _campo(
              key: const Key('trocar_senha_confirmacao'),
              controle: _confirmacao,
              rotulo: 'Repita a senha',
              erro: _erroConfirmacao,
              preenchimento: const [AutofillHints.newPassword],
              acao: TextInputAction.done,
              aoEnviar: (_) => _salvar(),
            ),
            if (erro != null) ...[
              const SizedBox(height: 12),
              Text(
                erro,
                key: const Key('trocar_senha_erro'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_enviando) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('trocar_senha_cancelar'),
            onPressed: _enviando ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('trocar_senha_salvar'),
            onPressed: _enviando ? null : _salvar,
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }
}
