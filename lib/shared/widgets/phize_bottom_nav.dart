import 'package:flutter/material.dart';

import '../../core/routing/app_routes.dart';

/// Navegação principal do aplicativo: Início, Histórico e Conta.
class PhizeBottomNav extends StatelessWidget {
  const PhizeBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        const rotas = [
          AppRoutes.dashboard,
          AppRoutes.historico,
          AppRoutes.meusDados,
        ];
        Navigator.of(context).pushReplacementNamed(rotas[index]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Histórico',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Conta',
        ),
      ],
    );
  }
}
