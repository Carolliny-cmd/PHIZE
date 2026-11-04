import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/conteudo_compartilhado.dart';
import '../domain/imagem_em_memoria.dart';

/// Converte a mensagem do código nativo em [ConteudoCompartilhado].
///
/// Imagem com texto sem link é só imagem: a legenda de uma foto não pede
/// escolha. O texto recebido não é guardado em nenhum dos casos.
ConteudoCompartilhado conteudoDeMensagem(Map<Object?, Object?> mensagem) {
  final bytes = mensagem['imagem'];
  final texto = mensagem['texto'];
  final imagem = bytes is Uint8List && bytes.isNotEmpty
      ? ImagemEmMemoria(bytes)
      : null;
  final link = texto is String ? extrairLink(texto) : null;

  if (imagem != null) {
    return link == null
        ? ImagemCompartilhada(imagem)
        : ImagemELinkCompartilhados(imagem: imagem, link: link);
  }
  if (link != null) return LinkCompartilhado(link);
  if (texto is String) return const TextoSemLink();
  return const ConteudoNaoSuportado();
}

/// Ponte com `MainActivity.kt`. Só existe no Android: em outras plataformas,
/// [iniciar] não faz nada (arquitetura de plataformas no ROADMAP).
class ReceptorCompartilhamento {
  static const MethodChannel _canal = MethodChannel(
    'com.phize.phize/compartilhamento',
  );

  /// Avisa o lado nativo de que pode entregar, e recebe o que chegou antes de
  /// o aplicativo terminar de abrir.
  Future<void> iniciar(
    void Function(ConteudoCompartilhado conteudo) aoReceber,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _canal.setMethodCallHandler((chamada) async {
      if (chamada.method == 'conteudoRecebido') {
        aoReceber(conteudoDeMensagem(chamada.arguments as Map<Object?, Object?>));
      }
    });
    final Map<Object?, Object?>? inicial = await _canal
        .invokeMapMethod<Object?, Object?>('pronto');
    if (inicial != null) aoReceber(conteudoDeMensagem(inicial));
  }
}
