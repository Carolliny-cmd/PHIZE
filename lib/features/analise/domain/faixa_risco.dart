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

  /// Variação com contraste suficiente para texto sobre fundo branco, e
  /// fundo de selo com texto branco em qualquer tema.
  Color get corTexto => switch (this) {
        FaixaRisco.baixo => const Color(0xFF15803D),
        FaixaRisco.medio => const Color(0xFF8A5A00),
        FaixaRisco.alto => const Color(0xFFC4261B),
      };

  /// Cor do texto da faixa sobre o fundo do tema em uso (RF14): no escuro,
  /// tons claros com contraste de pelo menos 4,5:1.
  Color corTextoEm(Brightness brilho) => brilho == Brightness.light
      ? corTexto
      : switch (this) {
          FaixaRisco.baixo => const Color(0xFF4ADE80),
          FaixaRisco.medio => const Color(0xFFFBBF24),
          FaixaRisco.alto => const Color(0xFFF87171),
        };
}
