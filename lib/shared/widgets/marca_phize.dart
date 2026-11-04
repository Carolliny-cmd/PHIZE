import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Nome do aplicativo como marca. Provisório até a criação do logo.
class MarcaPhize extends StatelessWidget {
  const MarcaPhize({super.key, this.tamanho = 22});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Text(
      'phize',
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: tamanho,
        fontWeight: FontWeight.w800,
        color: CoresPhize.azul,
      ),
    );
  }
}
