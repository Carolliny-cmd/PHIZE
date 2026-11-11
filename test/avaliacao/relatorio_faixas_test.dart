import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';

import 'comparacao_faixas.dart';

/// Converte um relatório de `npm run avaliar-analise` em faixas de risco,
/// com o motor do app (etapa 5 do plano do RAG).
///
///   flutter test test/avaliacao/relatorio_faixas_test.dart \
///     --dart-define=RELATORIO=2026-11-11-teste.json
///
/// Lê `functions/base-conhecimento/avaliacao/relatorios/<RELATORIO>`,
/// imprime o resumo e grava `<nome>-faixas.json` ao lado. Sem RELATORIO,
/// o teste é pulado: não faz parte da suíte normal.
const _relatorio = String.fromEnvironment('RELATORIO');
const _pasta = 'functions/base-conhecimento/avaliacao/relatorios';

void main() {
  test(
    'faixas com e sem a base',
    () {
      final arquivo = File('$_pasta/$_relatorio');
      final dados = jsonDecode(arquivo.readAsStringSync()) as Map<String, Object?>;
      final rodadas = [
        for (final r in dados['rodadas']! as List)
          RodadaRelatorio.deJson((r as Map).cast<String, Object?>()),
      ];
      final faixas = faixasPorMensagem(rodadas);
      final resumo = resumirFaixas(faixas);

      String contagem(Map<FaixaRisco, int> m) =>
          'verde ${m[FaixaRisco.baixo]} | amarelo ${m[FaixaRisco.medio]} | vermelho ${m[FaixaRisco.alto]}';

      final linhas = <String>['Relatório: $_relatorio (modelo ${dados['modelo']})'];
      const nomes = {
        TipoMensagem.golpeDaBase: 'Golpes da base',
        TipoMensagem.golpeForaDaBase: 'Golpes fora da base',
        TipoMensagem.legitima: 'Mensagens legítimas',
      };
      for (final MapEntry(key: tipo, value: r) in resumo.entries) {
        if (r.total == 0) continue;
        linhas
          ..add('\n${nomes[tipo]} (${r.total})')
          ..add('  sem a base: ${contagem(r.semBase)}')
          ..add('  com a base: ${contagem(r.comBase)}')
          ..add('  subiram com a base: ${r.subiram.length} ${r.subiram}')
          ..add('  desceram com a base: ${r.desceram.length} ${r.desceram}');
      }
      final foraComPadrao = faixas
          .where((f) => f.tipo != TipoMensagem.golpeDaBase && f.padraoComBase != null)
          .map((f) => '${f.mensagem} -> ${f.padraoComBase}')
          .toList();
      linhas.add('\nCorrespondência apontada em golpe fora da base ou legítima: '
          '${foraComPadrao.length} $foraComPadrao');
      // ignore: avoid_print
      print(linhas.join('\n'));

      final saida = File(
        '$_pasta/${_relatorio.replaceAll(RegExp(r'\.json$'), '')}-faixas.json',
      );
      saida.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({
              'relatorio': _relatorio,
              'modelo': dados['modelo'],
              'observacao':
                  'Faixa sem a base calculada sem a regra de verificação incompleta.',
              'resumo': {
                for (final e in resumo.entries) e.key.name: e.value.paraJson(),
              },
              'correspondenciaForaDoEsperado': foraComPadrao,
              'mensagens': [
                for (final f in faixas)
                  {
                    'mensagem': f.mensagem,
                    'tipo': f.tipo.name,
                    'semBase': f.semBase?.name,
                    'comBase': f.comBase?.name,
                    'padraoComBase': f.padraoComBase,
                  },
              ],
            })}\n',
      );
    },
    skip: _relatorio.isEmpty ? 'defina --dart-define=RELATORIO=<arquivo>' : false,
  );
}
