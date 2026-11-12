import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:integration_test/integration_test.dart';

/// Etapa 2 do plano do RAG: passa os prints sintéticos pelo ML Kit real, no
/// emulador Android, e grava as linhas reconhecidas com a posição de cada
/// uma (docs/calibracao-recuperacao.md, "Texto de print").
///
/// Só para prints FICTÍCIOS gerados por `tool/prints_sinteticos/gerar_prints.py`.
/// Este arquivo é ferramenta de avaliação, não faz parte do app: o fluxo real
/// nunca grava imagem em disco (RNF01). O roteiro de execução, que copia os
/// prints para a pasta do app e traz o resultado de volta, está em
/// `tool/prints_sinteticos/rodar_ocr.sh`.
const _pasta = String.fromEnvironment(
  'PASTA_PRINTS',
  defaultValue: '/data/user/0/com.phize.phize/files/prints_sinteticos',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OCR dos prints sintéticos', (tester) async {
    await tester.runAsync(() async {
      final indice = jsonDecode(File('$_pasta/indice.json').readAsStringSync())
          as Map<String, dynamic>;
      final prints = (indice['prints'] as List).cast<Map<String, dynamic>>();
      final saida = Directory('$_pasta/ocr')..createSync(recursive: true);
      final reconhecedor = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        for (final p in prints) {
          final id = p['id'] as String;
          final destino = File('${saida.path}/$id.json');
          if (destino.existsSync()) continue;
          final bytes = File('$_pasta/${p['arquivo']}').readAsBytesSync();
          final resultado = await _reconhecer(reconhecedor, bytes);
          destino.writeAsStringSync(
            jsonEncode({'id': id, 'tema': p['tema'], ...resultado}),
          );
          debugPrint('ocr $id');
        }
      } finally {
        await reconhecedor.close();
      }
      debugPrint('ocr concluido');
    });
  }, timeout: const Timeout(Duration(minutes: 20)));
}

/// Mesmo caminho do app (`ReconhecedorTextoMlKit`): decodifica em memória e
/// entrega os pixels ao ML Kit.
Future<Map<String, Object>> _reconhecer(
  TextRecognizer reconhecedor,
  Uint8List bytes,
) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final quadro = (await codec.getNextFrame()).image;
  try {
    final dados = await quadro.toByteData(format: ui.ImageByteFormat.rawRgba);
    final texto = await reconhecedor.processImage(
      InputImage.fromBitmap(
        bitmap: dados!.buffer.asUint8List(),
        width: quadro.width,
        height: quadro.height,
      ),
    );
    return {
      'largura': quadro.width,
      'altura': quadro.height,
      'texto': texto.text,
      'linhas': [
        for (final bloco in texto.blocks)
          for (final linha in bloco.lines)
            {
              'texto': linha.text,
              'esquerda': linha.boundingBox.left,
              'topo': linha.boundingBox.top,
              'direita': linha.boundingBox.right,
              'base': linha.boundingBox.bottom,
            },
      ],
    };
  } finally {
    quadro.dispose();
    codec.dispose();
  }
}
