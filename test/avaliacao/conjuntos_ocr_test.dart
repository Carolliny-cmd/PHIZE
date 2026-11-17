import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/shared/domain/mascaramento_local.dart';
import 'package:phize/shared/domain/organizacao_texto_print.dart';

/// Etapa 2 do plano do RAG: monta, a partir do OCR dos prints sintéticos,
/// três conjuntos de teste com o texto como o app o enviaria:
///
/// - `teste-ocr-bruto.json`: texto do ML Kit como vem hoje;
/// - `teste-ocr-ordenado.json`: ordem de leitura, sem textos da interface;
/// - `teste-ocr-recebidas.json`: além disso, só as mensagens recebidas.
///
/// Todos passam pelo mascaramento local do app (`mascararTextoLocal`).
///
///   flutter test test/avaliacao/conjuntos_ocr_test.dart --dart-define=GERAR_OCR=true
///
/// Se `build/prints_sinteticos/ocr/` existir (saída de
/// `tool/prints_sinteticos/rodar_ocr.sh`), junta os arquivos em
/// `avaliacao/ocr-teste.json`, que fica no repositório; depois disso o
/// emulador não é mais necessário para refazer os conjuntos.
const _gerar = bool.fromEnvironment('GERAR_OCR');
const _avaliacao = 'functions/base-conhecimento/avaliacao';

void main() {
  test(
    'conjuntos de teste a partir do OCR',
    () {
      final pastaOcr = Directory('build/prints_sinteticos/ocr');
      final arquivoOcr = File('$_avaliacao/ocr-teste.json');
      if (pastaOcr.existsSync()) {
        final resultados = [
          for (final f in pastaOcr.listSync().whereType<File>().toList()
            ..sort((a, b) => a.path.compareTo(b.path)))
            jsonDecode(f.readAsStringSync()),
        ];
        arquivoOcr.writeAsStringSync(
          '${const JsonEncoder.withIndent(' ').convert({
                'descricao':
                    'OCR (ML Kit, emulador Android) dos prints sintéticos de teste.json, '
                        'gerados por tool/prints_sinteticos. Conteúdo fictício.',
                'prints': resultados,
              })}\n',
        );
      }

      final ocr = {
        for (final p in (jsonDecode(arquivoOcr.readAsStringSync())
                as Map<String, dynamic>)['prints'] as List)
          (p as Map<String, dynamic>)['id'] as String: p,
      };
      final teste = jsonDecode(File('$_avaliacao/teste.json').readAsStringSync())
          as Map<String, dynamic>;

      String bruto(Map<String, dynamic> p) => p['texto'] as String;
      String organizado(Map<String, dynamic> p, {required bool recebidas}) =>
          organizarTextoPrint(
            [
              for (final l in (p['linhas'] as List).cast<Map<String, dynamic>>())
                LinhaReconhecida(
                  texto: l['texto'] as String,
                  esquerda: (l['esquerda'] as num).toDouble(),
                  topo: (l['topo'] as num).toDouble(),
                  direita: (l['direita'] as num).toDouble(),
                  base: (l['base'] as num).toDouble(),
                ),
            ],
            largura: (p['largura'] as num).toDouble(),
            somenteRecebidas: recebidas,
          );

      final variantes = <String, String Function(Map<String, dynamic>)>{
        'bruto': bruto,
        'ordenado': (p) => organizado(p, recebidas: false),
        'recebidas': (p) => organizado(p, recebidas: true),
      };

      for (final MapEntry(key: nome, value: extrair) in variantes.entries) {
        List<Map<String, Object?>> converter(List grupo) => [
              for (final m in grupo.cast<Map<String, dynamic>>())
                {
                  ...m,
                  'texto': mascararTextoLocal(extrair(ocr[m['id']]!)),
                },
            ];
        File('$_avaliacao/teste-ocr-$nome.json').writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert({
                'descricao':
                    'Gerado por test/avaliacao/conjuntos_ocr_test.dart a partir de '
                        'ocr-teste.json (variante "$nome"). Não editar à mão.',
                'tipo': 'teste',
                'golpes': converter(teste['golpes'] as List),
                'semGolpe': converter(teste['semGolpe'] as List),
              })}\n',
        );
      }
    },
    skip: _gerar ? false : 'defina --dart-define=GERAR_OCR=true',
  );
}
