import 'dart:convert';

import '../../analise/domain/analise_risco.dart';
import '../../analise/domain/faixa_risco.dart';
import '../../analise/domain/resultado_analise_print.dart';
import 'conta_repository.dart';

const String nomeArquivoExportacao = 'phize-meus-dados.json';

/// Compila os dados da conta em arquivo legível (RF12; UC12, passo 3). O
/// histórico só tem o resultado das análises, então o arquivo também não
/// traz nenhum conteúdo analisado (RNF01).
String montarExportacao({
  required PerfilConta perfil,
  required List<AnaliseRisco> analises,
  required DateTime geradoEm,
}) {
  final dados = {
    'geradoEm': geradoEm.toIso8601String(),
    'perfil': {
      'identificador': perfil.uid,
      'email': perfil.email,
      'nomeExibicao': perfil.nomeExibicao,
      'contaCriadaEm': perfil.criadaEm?.toIso8601String(),
    },
    'analises': [
      for (final analise in analises)
        {
          'data': analise.data.toIso8601String(),
          'tipoEntrada': switch (analise.tipoEntrada) {
            TipoEntrada.link => 'Link',
            TipoEntrada.imagem => 'Print',
          },
          'score': analise.score,
          'veredito': analise.faixa.rotulo,
          'categoria': analise.categoria?.nome,
          'explicacao': analise.explicacao,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(dados);
}
