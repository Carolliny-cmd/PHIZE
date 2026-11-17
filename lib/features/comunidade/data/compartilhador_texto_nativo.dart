import 'package:share_plus/share_plus.dart';

import '../domain/compartilhador_texto.dart';

/// Menu de compartilhamento do sistema. Só texto: não cria arquivo no cache.
class CompartilhadorTextoNativo implements CompartilhadorTexto {
  @override
  Future<void> compartilhar(String texto) async {
    await SharePlus.instance.share(ShareParams(text: texto));
  }
}
