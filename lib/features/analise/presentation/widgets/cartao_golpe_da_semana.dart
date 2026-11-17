import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/golpe_da_semana_asset.dart';
import '../../domain/golpe_da_semana.dart';

/// Cartão "Golpe da semana" na tela inicial (RF17). Lê o arquivo embutido
/// no app, sem rede. Se o arquivo não puder ser lido, o cartão não aparece:
/// é reforço educativo, não pode atrapalhar a análise.
class CartaoGolpeDaSemana extends StatefulWidget {
  const CartaoGolpeDaSemana({super.key, this.repositorio, this.agora});

  final GolpeDaSemanaRepository? repositorio;

  /// Relógio, para os testes. Por padrão, a hora atual.
  final DateTime Function()? agora;

  @override
  State<CartaoGolpeDaSemana> createState() => _CartaoGolpeDaSemanaState();
}

class _CartaoGolpeDaSemanaState extends State<CartaoGolpeDaSemana> {
  late final Future<FichaEducativa?> _ficha = _carregar();

  Future<FichaEducativa?> _carregar() async {
    try {
      final fichas = await (widget.repositorio ?? GolpeDaSemanaAsset())
          .fichas();
      return golpeDaSemana(fichas, (widget.agora ?? DateTime.now)());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FichaEducativa?>(
      future: _ficha,
      builder: (context, carga) {
        final ficha = carga.data;
        if (ficha == null) return const SizedBox.shrink();
        final tema = Theme.of(context).textTheme;
        final frase = ficha.frasesComuns.firstOrNull;
        return Card(
          key: const Key('golpe_da_semana'),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () =>
                Navigator.of(context)
                    .pushNamed(AppRoutes.golpeDaSemana, arguments: ficha),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: context.cores.azul,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Golpe da semana',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.cores.azul,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(ficha.modalidade, style: tema.titleMedium),
                  if (frase != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '"$frase"',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: context.cores.textoSecundario,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Ver sinais e o que fazer',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.cores.azul,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
