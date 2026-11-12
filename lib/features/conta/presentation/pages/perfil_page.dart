import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
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
import '../widgets/editar_nome_dialog.dart';
import '../widgets/excluir_conta_dialog.dart';

/// Tela de Perfil (RF14), aberta pela aba Perfil: identificação da conta e
/// os direitos do titular do RF12 (exportar e excluir), a privacidade da
/// análise de print e a saída da conta.
class PerfilPage extends StatefulWidget {
  const PerfilPage({
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

  static const String mensagemFalhaNome =
      'Não foi possível salvar o nome. Verifique sua conexão e tente '
      'novamente.';

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
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

  late final IdentidadeConta? _identidade = _lerIdentidade();
  String? _nome;
  bool _nomeCarregado = false;
  bool _processando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarNome();
  }

  IdentidadeConta? _lerIdentidade() {
    try {
      return _conta.identidade;
    } catch (_) {
      return null;
    }
  }

  Future<void> _carregarNome() async {
    try {
      final perfil = await _conta.carregarPerfil();
      if (!mounted) return;
      setState(() {
        _nome = perfil.nomeExibicao;
        _nomeCarregado = true;
      });
    } catch (_) {
      // Sem conexão, o nome fica como "não carregado"; editar continua
      // possível, porque só o nome é gravado.
    }
  }

  Future<void> _editarNome() async {
    final resultado = await showDialog<NomeEditado>(
      context: context,
      builder: (_) => EditarNomeDialog(nomeAtual: _nome),
    );
    if (resultado == null || !mounted) return;

    setState(() {
      _processando = true;
      _erro = null;
    });
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await _conta.salvarNomeExibicao(resultado.nome);
      if (!mounted) return;
      setState(() {
        _nome = resultado.nome;
        _nomeCarregado = true;
        _processando = false;
      });
      mensageiro.showSnackBar(
        SnackBar(
          content: Text(
            resultado.nome == null ? 'Nome removido.' : 'Nome salvo.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processando = false;
        _erro = PerfilPage.mensagemFalhaNome;
      });
    }
  }

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

  String get _formaDeLogin {
    final identidade = _identidade;
    if (identidade == null) return 'Não disponível';
    return [
      if (identidade.entraComSenha) 'E-mail e senha',
      if (identidade.entraComGoogle) 'Google',
    ].join(' e ');
  }

  @override
  Widget build(BuildContext context) {
    final erro = _erro;
    final identidade = _identidade;
    final habilitado = !_processando;

    return PopScope(
      canPop: !_processando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          // A exclusão em andamento decide sozinha para onde a tela vai.
          automaticallyImplyLeading: !_processando,
        ),
        bottomNavigationBar: const PhizeBottomNav(currentIndex: 2),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cabecalho(
                  nome: _nome,
                  email: identidade?.email,
                  emailVerificado: identidade?.emailVerificado,
                ),
                const SizedBox(height: 24),
                const _TituloSecao('Identificação'),
                _Secao(
                  children: [
                    ListTile(
                      key: const Key('perfil_nome'),
                      enabled: habilitado,
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Nome de exibição'),
                      subtitle: Text(
                        _nome ??
                            (_nomeCarregado
                                ? 'Não informado (opcional)'
                                : 'Toque para informar (opcional)'),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _editarNome,
                    ),
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('E-mail'),
                      subtitle: Text(identidade?.email ?? 'Não disponível'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Forma de login'),
                      subtitle: Text(_formaDeLogin),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _TituloSecao('Privacidade e dados'),
                _Secao(
                  children: [
                    ListTile(
                      key: const Key('perfil_exportar'),
                      enabled: habilitado,
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Exportar meus dados'),
                      subtitle: const Text(
                        'Arquivo com seu e-mail, nome de exibição, data do '
                        'cadastro e o resultado das suas análises. Você escolhe '
                        'onde salvar ou para quem enviar.',
                      ),
                      onTap: _exportar,
                    ),
                    ListTile(
                      key: const Key('perfil_privacidade'),
                      enabled: habilitado,
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacidade da análise de print'),
                      subtitle: const Text('Ver ou retirar sua autorização.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _abrirPrivacidade,
                    ),
                    ListTile(
                      key: const Key('perfil_excluir'),
                      enabled: habilitado,
                      iconColor: Theme.of(context).colorScheme.error,
                      textColor: Theme.of(context).colorScheme.error,
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Excluir minha conta'),
                      subtitle: const Text(
                        'Apaga definitivamente sua conta e todo o seu histórico '
                        'de análises.',
                      ),
                      onTap: _excluir,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  key: const Key('perfil_sair'),
                  onPressed: habilitado ? _sair : null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da conta'),
                ),
                if (_processando) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (erro != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    erro,
                    key: const Key('perfil_erro'),
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

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.nome,
    required this.email,
    required this.emailVerificado,
  });

  final String? nome;
  final String? email;
  final bool? emailVerificado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final base = nome ?? email ?? '?';
    final inicial = base.isEmpty ? '?' : base.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CoresPhize.azulClaro, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CoresPhize.borda),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: CoresPhize.azul,
              child: Text(
                inicial,
                style: textos.titleLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome ?? 'Olá!',
                  key: const Key('perfil_cabecalho_nome'),
                  style: textos.titleLarge,
                ),
                if (email != null)
                  Text(
                    email!,
                    style: textos.bodyMedium?.copyWith(
                      color: CoresPhize.textoSecundario,
                    ),
                  ),
                if (emailVerificado != null) ...[
                  const SizedBox(height: 6),
                  _SeloVerificacao(verificado: emailVerificado!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeloVerificacao extends StatelessWidget {
  const _SeloVerificacao({required this.verificado});

  final bool verificado;

  @override
  Widget build(BuildContext context) {
    final cor = verificado ? const Color(0xFF15803D) : const Color(0xFF8A5A00);
    return Container(
      key: Key(
        verificado ? 'perfil_email_verificado' : 'perfil_email_pendente',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verificado ? Icons.verified_outlined : Icons.schedule,
            size: 16,
            color: cor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              verificado ? 'E-mail verificado' : 'E-mail não verificado',
              style: TextStyle(color: cor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Material, e não um Container com cor, para o efeito de toque dos
    // itens aparecer.
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: CoresPhize.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, filho) in children.indexed) ...[
            if (i > 0)
              const Divider(height: 1, indent: 56, color: CoresPhize.borda),
            filho,
          ],
        ],
      ),
    );
  }
}
