import 'package:flutter/material.dart';

/// Paleta da direção visual "Leve". As cores do veredito ficam em
/// `FaixaRisco`, porque carregam o significado do semáforo (RF07).
class CoresPhize {
  CoresPhize._();

  static const Color azul = Color(0xFF3B5BDB);
  static const Color azulEscuro = Color(0xFF2B46B8);
  static const Color azulClaro = Color(0xFFEEF2FF);
  static const Color tinta = Color(0xFF111B3D);
  static const Color textoSecundario = Color(0xFF56607A);
  static const Color fundoSuave = Color(0xFFF5F6FA);
  static const Color borda = Color(0xFFDDE1EC);
  static const Color erro = Color(0xFFB42318);
  static const Color erroClaro = Color(0xFFFEECEB);
}

class AppTheme {
  AppTheme._();

  static const double _raio = 18;

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: CoresPhize.azul,
      onPrimary: Colors.white,
      secondaryContainer: CoresPhize.azulClaro,
      onSecondaryContainer: CoresPhize.azulEscuro,
      surface: Colors.white,
      onSurface: CoresPhize.tinta,
      onSurfaceVariant: CoresPhize.textoSecundario,
      surfaceContainerHighest: CoresPhize.fundoSuave,
      outline: CoresPhize.borda,
      error: CoresPhize.erro,
      onError: Colors.white,
      errorContainer: CoresPhize.erroClaro,
      onErrorContainer: CoresPhize.erro,
    );

    final formaBotao = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_raio),
    );
    const textoBotao = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );
    const tamanhoBotao = Size.fromHeight(60);
    final bordaCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 17, height: 1.45),
        bodyMedium: TextStyle(fontSize: 16, height: 1.45),
        bodySmall: TextStyle(fontSize: 14, height: 1.4),
      ).apply(bodyColor: CoresPhize.tinta, displayColor: CoresPhize.tinta),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: CoresPhize.tinta,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: CoresPhize.tinta,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tamanhoBotao,
          shape: formaBotao,
          textStyle: textoBotao,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tamanhoBotao,
          shape: formaBotao,
          textStyle: textoBotao,
          side: const BorderSide(color: CoresPhize.borda),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textoBotao.copyWith(fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoresPhize.fundoSuave,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: bordaCampo,
        enabledBorder: bordaCampo,
        focusedBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: CoresPhize.azul, width: 2),
        ),
        errorBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: CoresPhize.erro),
        ),
        focusedErrorBorder: bordaCampo.copyWith(
          borderSide: const BorderSide(color: CoresPhize.erro, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: CoresPhize.fundoSuave,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_raio),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: CoresPhize.azulClaro,
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: estados.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: estados.contains(WidgetState.selected)
                ? CoresPhize.azulEscuro
                : CoresPhize.textoSecundario,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CoresPhize.tinta,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
