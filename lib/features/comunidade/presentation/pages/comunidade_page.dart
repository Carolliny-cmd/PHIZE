import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../data/feed_repository_firestore.dart';
import '../../data/moderacao_repository_firestore.dart';
import '../../domain/feed_repository.dart';
import '../../domain/moderacao_repository.dart';
import '../../domain/reporte_comunidade.dart';

/// Aba "Comunidade" (RF08, UC07): reportes de outras pessoas, "Em alta" ou
/// "Mais recentes". Reportes ocultos pela moderação não aparecem (RF11).
class ComunidadePage extends StatefulWidget {
  const ComunidadePage({super.key, this.repositorio, this.moderacao});

  final FeedRepository? repositorio;
  final ModeracaoRepository? moderacao;

  static const String avisoFeed =
      'Relatos enviados por pessoas do Phize, sem nome. Nem todos foram '
      'revisados pela equipe.';

  @override
  State<ComunidadePage> createState() => _ComunidadePageState();
}

class _ComunidadePageState extends State<ComunidadePage> {
  // Resolvido só quando usado: o repositório real exige o Firebase
  // inicializado.
  late final FeedRepository _repositorio =
      widget.repositorio ?? FeedRepositoryFirestore();
  OrdemFeed _ordem = OrdemFeed.emAlta;
  late Future<List<ReporteComunidade>> _reportes = _repositorio.listar(_ordem);

  /// A entrada da moderação só aparece para contas da lista `moderadores`
  /// (RF11). Esconder o botão é conveniência; o acesso é barrado pelas
  /// regras do Firestore.
  bool _moderador = false;

  @override
  void initState() {
    super.initState();
    _conferirModeracao();
  }

  Future<void> _conferirModeracao() async {
    bool moderador;
    try {
      final moderacao = widget.moderacao ?? ModeracaoRepositoryFirestore();
      moderador = await moderacao.ehModerador();
    } catch (_) {
      moderador = false;
    }
    if (mounted && moderador) setState(() => _moderador = true);
  }

  Future<void> _abrirModeracao() async {
    await Navigator.of(context).pushNamed(AppRoutes.moderacao);
    if (mounted) _recarregar();
  }

  void _recarregar() {
    setState(() {
      _reportes = _repositorio.listar(_ordem);
    });
  }

  void _mudarOrdem(OrdemFeed ordem) {
    if (ordem == _ordem) return;
    _ordem = ordem;
    _recarregar();
  }

  Future<void> _abrir(ReporteComunidade reporte) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.detalheReporte, arguments: reporte);
    // A curtida dada no detalhe muda a contagem e, em "Em alta", a ordem.
    if (mounted) _recarregar();
  }

  Future<void> _reportar() async {
    await Navigator.of(context).pushNamed(AppRoutes.reportarGolpe);
    if (mounted) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidade'),
        actions: [
          if (_moderador)
            IconButton(
              key: const Key('comunidade_moderacao'),
              tooltip: 'Moderação',
              onPressed: _abrirModeracao,
              icon: const Icon(Icons.shield_outlined),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<OrdemFeed>(
              key: const Key('comunidade_ordem'),
              segments: [
                for (final ordem in OrdemFeed.values)
                  ButtonSegment(value: ordem, label: Text(ordem.nome)),
              ],
              selected: {_ordem},
              showSelectedIcon: false,
              onSelectionChanged: (escolha) => _mudarOrdem(escolha.single),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              ComunidadePage.avisoFeed,
              style: TextStyle(
                fontSize: 14,
                color: context.cores.textoSecundario,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReporteComunidade>>(
              future: _reportes,
              builder: (context, carga) {
                if (carga.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reportes = carga.data;
                if (carga.hasError || reportes == null) {
                  return _FalhaCarga(aoTentarDeNovo: _recarregar);
                }
                if (reportes.isEmpty) {
                  return const _FeedVazio();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _recarregar();
                    await _reportes.catchError((_) => <ReporteComunidade>[]);
                  },
                  child: ListView.separated(
                    key: const Key('comunidade_lista'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: reportes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _CartaoReporte(
                      reporte: reportes[i],
                      aoTocar: () => _abrir(reportes[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('comunidade_reportar'),
        onPressed: _reportar,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Reportar golpe'),
      ),
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 1),
    );
  }
}

class _CartaoReporte extends StatelessWidget {
  const _CartaoReporte({required this.reporte, required this.aoTocar});

  final ReporteComunidade reporte;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );
    final curtidas = reporte.curtidas == 1
        ? '1 curtida'
        : '${reporte.curtidas} curtidas';

    return Card(
      key: Key('comunidade_reporte_${reporte.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reporte.titulo, style: tema.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${reporte.categoria.nome} · ${formatarData(reporte.criadoEm)}',
                style: secundario,
              ),
              const SizedBox(height: 8),
              // Wrap: com letra grande, a marca de "não revisado" desce
              // para a linha de baixo em vez de estourar (RF14).
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 18,
                        color: context.cores.textoSecundario,
                      ),
                      const SizedBox(width: 6),
                      Text(curtidas, style: secundario),
                    ],
                  ),
                  if (reporte.status == StatusReporte.pendente)
                    Text('Ainda não revisado', style: secundario),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedVazio extends StatelessWidget {
  const _FeedVazio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 48,
              color: context.cores.textoSecundario,
            ),
            const SizedBox(height: 12),
            const Text(
              'Ainda não há reportes na comunidade.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Recebeu um golpe? Avise outras pessoas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.cores.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _FalhaCarga extends StatelessWidget {
  const _FalhaCarga({required this.aoTentarDeNovo});

  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar a comunidade. Verifique sua conexão.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('comunidade_tentar_de_novo'),
              onPressed: aoTentarDeNovo,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
