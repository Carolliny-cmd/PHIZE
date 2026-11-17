import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/golpe_da_semana.dart';

/// Caminho do arquivo gerado por `tool/gerar_golpe_da_semana.dart` a partir
/// das fichas revisadas da base de conhecimento.
const String caminhoGolpeDaSemana = 'assets/conteudo/golpe_da_semana.json';

/// Lê as fichas do arquivo embutido no app, sem rede (RF17).
class GolpeDaSemanaAsset implements GolpeDaSemanaRepository {
  GolpeDaSemanaAsset({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<List<FichaEducativa>> fichas() async {
    final dados = jsonDecode(await _bundle.loadString(caminhoGolpeDaSemana));
    final lista = dados is Map ? dados['fichas'] : null;
    if (lista is! List) return const [];
    return [for (final item in lista) ?FichaEducativa.doJson(item)];
  }
}
