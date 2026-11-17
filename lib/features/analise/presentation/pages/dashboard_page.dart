import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/marca_phize.dart';
import '../../../../shared/widgets/phize_bottom_nav.dart';
import '../../domain/golpe_da_semana.dart';
import '../widgets/cartao_golpe_da_semana.dart';

/// Tela inicial: uma pergunta e duas ações, analisar print ou link (RF03,
/// RF04). O print vem primeiro por ser o caso mais comum. Abaixo, o cartão
/// "Golpe da semana" (RF17).
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.golpeDaSemanaRepository, this.agora});

  final GolpeDaSemanaRepository? golpeDaSemanaRepository;

  /// Relógio do rodízio semanal, para os testes.
  final DateTime Function()? agora;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const MarcaPhize()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Recebeu algo estranho?', style: tema.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Veja se é golpe antes de responder.',
              style: tema.bodyLarge?.copyWith(
                color: context.cores.textoSecundario,
              ),
            ),
            const SizedBox(height: 32),
            // Na web não há seleção de imagem com Zero-Persistence nem OCR
            // embarcado (SeletorImagemGaleria, ReconhecedorTextoMlKit).
            FilledButton.icon(
              key: const Key('dashboard_analisar_print'),
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: kIsWeb
                  ? null
                  : () =>
                        Navigator.of(context)
                            .pushNamed(AppRoutes.analisarPrint),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Analisar print'),
            ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Disponível apenas em dispositivos móveis (Android/iOS).',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.cores.textoSecundario,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('dashboard_analisar_link'),
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                backgroundColor: context.cores.azulClaro,
                foregroundColor: context.cores.azulEscuro,
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.analisarLink),
              icon: const Icon(Icons.link),
              label: const Text('Analisar link'),
            ),
            const SizedBox(height: 32),
            CartaoGolpeDaSemana(
              repositorio: golpeDaSemanaRepository,
              agora: agora,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PhizeBottomNav(currentIndex: 0),
    );
  }
}
