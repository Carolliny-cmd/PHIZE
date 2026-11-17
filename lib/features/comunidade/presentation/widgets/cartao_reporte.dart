import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/domain/formatacao_data.dart';
import '../../domain/reporte_comunidade.dart';

/// Cartão de um reporte no feed e na pesquisa (RF08, RF15): título, tipo de
/// golpe, data e curtidas, e a marca de "Ainda não revisado".
class CartaoReporte extends StatelessWidget {
  const CartaoReporte({
    super.key,
    required this.reporte,
    required this.aoTocar,
  });

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
