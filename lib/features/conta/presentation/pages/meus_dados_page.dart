import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../../analise/data/consentimento_repository_local.dart';
import '../../../analise/data/historico_repository_firestore.dart';
import '../../../analise/domain/consentimento_repository.dart';
import '../../../analise/domain/historico_repository.dart';
import '../../../analise/presentation/pages/consentimento_page.dart';
import '../../../auth/data/firebase_auth_repository.dart';
import '../../../auth/domain/auth_exception.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../data/compartilhador_arquivo_nativo.dart';
import '../../data/conta_repository_firebase.dart';
import '../../domain/compartilhador_arquivo.dart';
import '../../domain/conta_repository.dart';
import '../../domain/exportacao_dados.dart';
import '../widgets/excluir_conta_dialog.dart';

/// Tela "Meus dados" (RF12 / UC12): exportar os dados ou excluir a conta.
class MeusDadosPage extends StatefulWidget {
  const MeusDadosPage({
    super.key,
    this.contaRepository,
    this.historicoRepository,
    this.compartilhador,
    this.authRepository,
    this.consentimentoRepository,
  });

  final ContaRepository? contaRepository;
  final HistoricoRepository? historicoRepository;
  final CompartilhadorArquivo? compartilhador;
  final AuthRepository? authRepository;
  final ConsentimentoRepository? consentimentoRepository;

  @override
  State<MeusDadosPage> createState() => _MeusDadosPageState();
}

class _MeusDadosPageState extends State<MeusDadosPage> {
  // Resolvidos só quando usados: os repositórios reais exigem o Firebase
  // inicializado.
  late final ContaRepository _conta =
      widget.contaRepository ?? ContaRepositoryFirebase();
  late final HistoricoRepository _historico =
      widget.historicoRepository ?? HistoricoRepositoryFirestore();
  late final CompartilhadorArquivo _compartilhador =
      widget.compartilhador ?? CompartilhadorArquivoNativo();
  late final AuthRepository _auth =
      widget.authRepository ?? FirebaseAuthRepository();
  late final ConsentimentoRepository _consentimento =
      widget.consentimentoRepository ?? ConsentimentoRepositoryLocal();

  bool _processando = false;
  String? _erro;

  Future<void> _exportar() async {
    setState(() {
      _processando = true;
      _erro = null;
    });
    try {
      final conteudo = montarExportacao(
        perfil: await _conta.carregarPerfil(),
        analises: await _historico.listar(somenteServidor: true),
        geradoEm: DateTime.now(),
      );
      await _compartilhador.compartilhar(
        nomeArquivo: nomeArquivoExportacao,
        conteudo: conteudo,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro =
              'Não foi possível exportar seus dados. Verifique sua conexão e '
              'tente novamente.';
        });
      }
    }
    if (mounted) setState(() => _processando = false);
  }

  Future<void> _excluir() async {
    final senha = await showDialog<String>(
      context: context,
      builder: (_) => ExcluirContaDialog(exigeSenha: _conta.exigeSenha),
    );
    if (senha == null || !mounted) return;

    setState(() {
      _processando = true;
      _erro = null;
    });
    final navegador = Navigator.of(context);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await _conta.excluirConta(senha: senha.isEmpty ? null : senha);
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Sua conta foi excluída.')),
      );
      await navegador.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _erro = e.mensagem;
      });
    } on ExclusaoIncompletaException {
      await navegador.pushNamedAndRemoveUntil(
        AppRoutes.exclusaoPendente,
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _erro =
            'Não foi possível excluir sua conta, e nada foi apagado. '
            'Verifique sua conexão e tente novamente.';
      });
    }
  }

  void _abrirPrivacidade() {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConsentimentoPage(repositorio: _consentimento),
      ),
    );
  }

  Future<void> _sair() async {
    final navegador = Navigator.of(context);
    try {
      await _auth.sair();
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível sair. Tente novamente.');
      }
      return;
    }
    await navegador.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(context).textTheme.titleMedium;
    final erro = _erro;

    return PopScope(
      canPop: !_processando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus dados'),
          // A exclusão em andamento decide sozinha para onde a tela vai.
          automaticallyImplyLeading: !_processando,
        ),
        bottomNavigationBar: const PhizeBottomNav(currentIndex: 2),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Exportar meus dados', style: titulo),
                const SizedBox(height: 4),
                const Text(
                  'Gera um arquivo com seu e-mail, a data do cadastro e o '
                  'resultado das suas análises. Você escolhe onde salvar ou '
                  'para quem enviar.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('meus_dados_exportar'),
                  onPressed: _processando ? null : _exportar,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Exportar meus dados'),
                ),
                const SizedBox(height: 32),
                Text('Excluir minha conta', style: titulo),
                const SizedBox(height: 4),
                const Text(
                  'Apaga definitivamente sua conta e todo o seu histórico de '
                  'análises.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('meus_dados_excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _processando ? null : _excluir,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir minha conta'),
                ),
                const SizedBox(height: 32),
                TextButton(
                  key: const Key('meus_dados_privacidade'),
                  onPressed: _processando ? null : _abrirPrivacidade,
                  child: const Text('Privacidade da análise de print'),
                ),
                TextButton(
                  key: const Key('meus_dados_sair'),
                  onPressed: _processando ? null : _sair,
                  child: const Text('Sair da conta'),
                ),
                if (_processando) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (erro != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    erro,
                    key: const Key('meus_dados_erro'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
