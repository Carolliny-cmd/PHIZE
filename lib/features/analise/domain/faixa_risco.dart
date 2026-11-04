import 'package:flutter/material.dart';

import 'rotulos_risco.dart';

/// As três faixas do Score de Risco (RF07), na escala semafórica.
enum FaixaRisco { baixo, medio, alto }

extension FaixaRiscoRotulo on FaixaRisco {
  String get rotulo => switch (this) {
        FaixaRisco.baixo => RotulosRisco.baixoRisco,
        FaixaRisco.medio => RotulosRisco.medioRisco,
        FaixaRisco.alto => RotulosRisco.altoRisco,
      };

  String get oQueFazer => switch (this) {
        FaixaRisco.baixo => RotulosRisco.oQueFazerBaixoRisco,
        FaixaRisco.medio => RotulosRisco.oQueFazerMedioRisco,
        FaixaRisco.alto => RotulosRisco.oQueFazerAltoRisco,
      };

  /// Cor do medidor.
  Color get cor => switch (this) {
        FaixaRisco.baixo => const Color(0xFF16A34A),
        FaixaRisco.medio => const Color(0xFFF5A400),
        FaixaRisco.alto => const Color(0xFFD92D20),
      };

  /// Variação com contraste suficiente para texto sobre fundo branco.
  Color get corTexto => switch (this) {
        FaixaRisco.baixo => const Color(0xFF15803D),
        FaixaRisco.medio => const Color(0xFF8A5A00),
        FaixaRisco.alto => const Color(0xFFC4261B),
      };
}
