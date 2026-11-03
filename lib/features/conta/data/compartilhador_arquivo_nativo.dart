import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/compartilhador_arquivo.dart';

/// Abre o menu de compartilhamento do sistema, onde a pessoa escolhe salvar
/// o arquivo ou enviá-lo a outro aplicativo.
class CompartilhadorArquivoNativo implements CompartilhadorArquivo {
  @override
  Future<void> compartilhar({
    required String nomeArquivo,
    required String conteudo,
  }) async {
    final arquivo = XFile.fromData(
      utf8.encode(conteudo),
      mimeType: 'application/json',
    );
    await SharePlus.instance.share(
      ShareParams(files: [arquivo], fileNameOverrides: [nomeArquivo]),
    );
  }

  /// Remove a cópia que o `share_plus` deixa no cache do app: ela traz o
  /// e-mail e o histórico, e não some sozinha. Não pode ser apagada logo após
  /// o compartilhamento, porque o aplicativo escolhido ainda pode estar
  /// lendo o arquivo; por isso sai na abertura seguinte do app e na exclusão
  /// da conta. Nunca lança.
  static Future<void> removerCopiaLocal() async {
    try {
      final cache = await getTemporaryDirectory();
      final pasta = Directory('${cache.path}/share_plus');
      if (await pasta.exists()) await pasta.delete(recursive: true);
    } catch (_) {
      // Fica para a próxima abertura do app.
    }
  }
}
