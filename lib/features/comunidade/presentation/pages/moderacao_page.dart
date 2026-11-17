import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../data/moderacao_repository_firestore.dart';
import '../../domain/moderacao_repository.dart';
import '../../domain/motivo_denuncia.dart';
import '../../domain/reporte_comunidade.dart';

/// Moderação mínima da comunidade (RF11): aprovar, ocultar ou excluir de vez
/// um reporte. Só aparece para contas da lista `moderadores`; quem garante o
/// acesso são as regras do Firestore, não esta tela.
class ModeracaoPage extends StatefulWidget {
  const ModeracaoPage({super.key, this.repositorio});

  final ModeracaoRepository? repositorio;

  @override
  State<ModeracaoPage> createState() => _ModeracaoPageState();
}

class _ModeracaoPageState extends State<ModeracaoPage> {
  late final ModeracaoRepository _repositorio =
      widget.repositorio ?? ModeracaoRepositoryFirestore();

  /// Começa pelos ocultos: são os que esperam revisão depois de denúncias.
  StatusReporte _lista = StatusReporte.oculto;
  late Future<List<ReporteComunidade>> _reportes = _repositorio.listar(_lista);

  void _recarregar() {
    setState(() {
      _reportes = _repositorio.listar(_lista);
    });
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await acao();
      mensageiro.showSnackBar(SnackBar(content: Text(sucesso)));
    } catch (_) {
      mensageiro.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível concluir. Tente de novo.'),
        ),
      );
    }
    if (mounted) _recarregar();
  }

  Future<void> _mudarStatus(ReporteComunidade reporte, StatusReporte novo) =>
      _executar(() => _repositorio.mudarStatus(reporte, novo), switch (novo) {
        StatusReporte.aprovado => 'Reporte aprovado.',
        StatusReporte.oculto => 'Reporte ocultado do feed.',
        StatusReporte.pendente => 'Reporte devolvido a pendente.',
      });

  Future<void> _excluir(ReporteComunidade reporte) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Excluir de vez?'),
        content: Text(
          '"${reporte.titulo}" será removido da comunidade. '
          'Não dá para desfazer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('moderacao_confirmar_exclusao'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    await _executar(
      () => _repositorio.excluir(reporte.id),
      'Reporte excluído.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderação')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<StatusReporte>(
              key: const Key('moderacao_lista'),
              segments: [
                for (final status in [
                  StatusReporte.oculto,
                  StatusReporte.pendente,
                  StatusReporte.aprovado,
                ])
                  ButtonSegment(value: status, label: Text(status.nomeLista)),
              ],
              selected: {_lista},
              showSelectedIcon: false,
              onSelectionChanged: (escolha) {
                _lista = escolha.single;
                _recarregar();
              },
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Não foi possível carregar os reportes.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _recarregar,
                            child: const Text('Tentar de novo'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (reportes.isEmpty) {
                  return const Center(
                    child: Text('Nenhum reporte nesta lista.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: reportes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _CartaoModeracao(
                    key: Key('moderacao_${reportes[i].id}'),
                    reporte: reportes[i],
                    repositorio: _repositorio,
                    aoMudarStatus: (novo) => _mudarStatus(reportes[i], novo),
                    aoExcluir: () => _excluir(reportes[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoModeracao extends StatefulWidget {
  const _CartaoModeracao({
    super.key,
    required this.reporte,
    required this.repositorio,
    required this.aoMudarStatus,
    required this.aoExcluir,
  });

  final ReporteComunidade reporte;
  final ModeracaoRepository repositorio;
  final ValueChanged<StatusReporte> aoMudarStatus;
  final VoidCallback aoExcluir;

  @override
  State<_CartaoModeracao> createState() => _CartaoModeracaoState();
}

class _CartaoModeracaoState extends State<_CartaoModeracao> {
  Future<Map<MotivoDenuncia, int>>? _motivos;

  @override
  void initState() {
    super.initState();
    if (widget.reporte.denuncias > 0) {
      _motivos = widget.repositorio.motivosDasDenuncias(widget.reporte.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final tema = Theme.of(context).textTheme;
    final secundario = TextStyle(
      fontSize: 14,
      color: context.cores.textoSecundario,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reporte.titulo, style: tema.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${reporte.categoria.nome} · ${reporte.tipo.nome} · '
              '${formatarData(reporte.criadoEm)}',
              style: secundario,
            ),
            if (reporte.relato.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reporte.relato, style: tema.bodyMedium),
            ],
            const SizedBox(height: 8),
            Text(
              '${reporte.denuncias} denúncia(s) · ${reporte.curtidas} '
              'curtida(s) · ${reporte.incidencias} relato(s)',
              style: secundario,
            ),
            if (_motivos case final motivos?)
              FutureBuilder<Map<MotivoDenuncia, int>>(
                future: motivos,
                builder: (context, carga) {
                  final contagem = carga.data;
                  if (contagem == null || contagem.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        for (final MapEntry(key: motivo, value: n)
                            in contagem.entries)
                          '${motivo.nome}: $n',
                      ].join('\n'),
                      style: secundario,
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (reporte.status != StatusReporte.aprovado)
                  TextButton(
                    key: Key('moderacao_aprovar_${reporte.id}'),
                    onPressed: () =>
                        widget.aoMudarStatus(StatusReporte.aprovado),
                    child: const Text('Aprovar'),
                  ),
                if (reporte.status != StatusReporte.oculto)
                  TextButton(
                    key: Key('moderacao_ocultar_${reporte.id}'),
                    onPressed: () => widget.aoMudarStatus(StatusReporte.oculto),
                    child: const Text('Ocultar'),
                  ),
                TextButton(
                  key: Key('moderacao_excluir_${reporte.id}'),
                  onPressed: widget.aoExcluir,
                  style: TextButton.styleFrom(
                    foregroundColor: context.cores.erro,
                  ),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
