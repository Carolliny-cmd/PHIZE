import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../data/historico_repository_firestore.dart';
import '../../domain/analisador_link.dart';
import '../../domain/analise_risco.dart';
import '../../data/tutorial_repository_local.dart';
import '../../domain/historico_repository.dart';
import '../../domain/tutorial_repository.dart';
import '../registro_historico.dart';
import '../tutorial/tutorial_link.dart';
import '../tutorial/tutorial_page.dart';

/// Tela "Analisar Link" (UC03, passos 1 e 2): o usuário cola a URL e
/// aciona a verificação. O endereço fica apenas em memória, no campo de
/// texto, e é limpo assim que a análise termina — nunca é persistido
/// (UC03, pós-condições).
class AnalisarLinkPage extends StatefulWidget {
  const AnalisarLinkPage({
    super.key,
    required this.analisadorLink,
    this.historicoRepository,
    this.tutorialRepository,
  });

  final AnalisadorLink analisadorLink;
  final HistoricoRepository? historicoRepository;
  final TutorialRepository? tutorialRepository;

  @override
  State<AnalisarLinkPage> createState() => _AnalisarLinkPageState();
}

class _AnalisarLinkPageState extends State<AnalisarLinkPage> {
  // Resolvido só quando usado: criar o repositório real exige o Firebase
  // inicializado.
  late final HistoricoRepository _historico =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late final TutorialRepository _tutorial =
      widget.tutorialRepository ?? TutorialRepositoryLocal();
  final _urlController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Tutorial de primeiro uso (RF13), depois que a tela aparece.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      abrirTutorialNaPrimeiraVez(
        context,
        tipo: TipoTutorial.link,
        repositorio: _tutorial,
        construir: (_) => const TutorialLinkPage(),
      );
    });
  }

  void _abrirTutorial() => abrirTutorial(
    context,
    tipo: TipoTutorial.link,
    repositorio: _tutorial,
    construir: (_) => const TutorialLinkPage(),
  );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    // Feedback de carregamento imediato após a submissão (RNF03).
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await widget.analisadorLink.analisar(_urlController.text);
    if (!mounted) return;

    if (resultado == null) {
      setState(() {
        _carregando = false;
        _erro =
            'Isso não parece ser um link. Confira o endereço e envie '
            'novamente (exemplo: site.com.br).';
      });
      return;
    }

    _urlController.clear();
    setState(() => _carregando = false);
    registrarNoHistorico(
      mensageiro: ScaffoldMessenger.of(context),
      repositorio: _historico,
      analise: AnaliseRisco.doLink(resultado, DateTime.now()),
    );
    await Navigator.of(context).pushNamed(
      AppRoutes.resultado,
      arguments: resultado,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisar link'),
        actions: [
          IconButton(
            key: const Key('analisar_link_ajuda'),
            tooltip: 'Como funciona',
            icon: const Icon(Icons.help_outline),
            onPressed: _carregando ? null : _abrirTutorial,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cole abaixo o link que você recebeu.'),
              const SizedBox(height: 16),
              TextField(
                key: const Key('analisar_link_url'),
                controller: _urlController,
                enabled: !_carregando,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Link',
                  hintText: 'https://...',
                  border: const OutlineInputBorder(),
                  errorText: _erro,
                  errorMaxLines: 3,
                ),
                onSubmitted: (_) => _carregando ? null : _verificar(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('analisar_link_botao'),
                onPressed: _carregando ? null : _verificar,
                child: const Text('Verificar link'),
              ),
              if (_carregando) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const Text(
                  'Analisando o link…',
                  key: Key('analisar_link_carregando'),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
