import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/preferencias_aparencia.dart';

/// Disponibiliza as preferências de acessibilidade (RF14) para o app
/// inteiro e aplica o tema e o tamanho da letra em todas as telas.
class EscopoPreferencias extends InheritedNotifier<ControlePreferencias> {
  const EscopoPreferencias({
    super.key,
    required ControlePreferencias controle,
    required super.child,
  }) : super(notifier: controle);

  /// `null` fora do app, como em testes de uma tela isolada.
  static ControlePreferencias? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EscopoPreferencias>()
      ?.notifier;
}

extension TemaPreferidoModo on TemaPreferido {
  ThemeMode get modo => switch (this) {
        TemaPreferido.sistema => ThemeMode.system,
        TemaPreferido.claro => ThemeMode.light,
        TemaPreferido.escuro => ThemeMode.dark,
      };
}

/// Monta o [MaterialApp] com o tema e o tamanho da letra escolhidos.
/// [construir] recebe os parâmetros de tema e o `builder` a repassar.
class AparenciaApp extends StatelessWidget {
  const AparenciaApp({
    super.key,
    required this.controle,
    required this.construir,
  });

  final ControlePreferencias controle;
  final Widget Function(
    ThemeData claro,
    ThemeData escuro,
    ThemeMode modo,
    TransitionBuilder builder,
  ) construir;

  @override
  Widget build(BuildContext context) {
    return EscopoPreferencias(
      controle: controle,
      child: ListenableBuilder(
        listenable: controle,
        builder: (context, _) {
          final preferencias = controle.atual;
          return construir(
            AppTheme.light,
            AppTheme.dark,
            preferencias.tema.modo,
            (context, filho) {
              final consulta = MediaQuery.of(context);
              return MediaQuery(
                data: consulta.copyWith(
                  textScaler: aplicarTamanhoLetra(
                    consulta.textScaler,
                    preferencias.tamanhoLetra,
                  ),
                ),
                child: filho ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
