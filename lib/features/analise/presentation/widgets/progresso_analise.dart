import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/analisador_print.dart';

/// Mostra a etapa real da análise de print e avisa quando ela demora, para a
/// pessoa não achar que o aplicativo travou (RNF03). A etapa vem do pipeline:
/// não há barra nem tempo estimado, porque a demora do provedor varia muito.
class ProgressoAnalise extends StatefulWidget {
  const ProgressoAnalise({super.key, required this.etapa});

  static const Duration tempoParaAviso = Duration(seconds: 10);
  static const String avisoDemora =
      'Está demorando um pouco mais que o normal. Pode aguardar, a análise '
      'continua.';

  final EtapaAnalisePrint etapa;

  @override
  State<ProgressoAnalise> createState() => _ProgressoAnaliseState();
}

class _ProgressoAnaliseState extends State<ProgressoAnalise> {
  Timer? _temporizador;
  bool _demorando = false;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(ProgressoAnalise.tempoParaAviso, () {
      if (mounted) setState(() => _demorando = true);
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final etapa in EtapaAnalisePrint.values)
            _LinhaEtapa(etapa: etapa, atual: widget.etapa),
          if (_demorando) ...[
            const SizedBox(height: 8),
            const Text(
              ProgressoAnalise.avisoDemora,
              key: Key('progresso_aviso_demora'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaEtapa extends StatelessWidget {
  const _LinhaEtapa({required this.etapa, required this.atual});

  final EtapaAnalisePrint etapa;
  final EtapaAnalisePrint atual;

  @override
  Widget build(BuildContext context) {
    final concluida = etapa.index < atual.index;
    final emAndamento = etapa == atual;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 26,
            child: concluida
                ? const Icon(Icons.check_circle, color: CoresPhize.azul)
                : emAndamento
                ? const Padding(
                    padding: EdgeInsets.all(3),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Icon(
                    Icons.radio_button_unchecked,
                    color: CoresPhize.borda,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              etapa.titulo,
              style: TextStyle(
                color: concluida || emAndamento
                    ? CoresPhize.tinta
                    : CoresPhize.textoSecundario,
                fontWeight: emAndamento ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
