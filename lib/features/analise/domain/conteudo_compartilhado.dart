import '../../../shared/domain/imagem_em_memoria.dart';

/// Conteúdo recebido pelo menu de compartilhamento do sistema (RF10 / UC11),
/// mantido só em memória (RNF01). Quem o recebe chama [descartar] ao terminar
/// ou ao desistir dele.
sealed class ConteudoCompartilhado {
  const ConteudoCompartilhado();

  void descartar() {}
}

final class ImagemCompartilhada extends ConteudoCompartilhado {
  const ImagemCompartilhada(this.imagem);

  final ImagemEmMemoria imagem;

  @override
  void descartar() => imagem.descartar();
}

final class LinkCompartilhado extends ConteudoCompartilhado {
  const LinkCompartilhado(this.link);

  final String link;
}

/// Imagem e link na mesma submissão: o usuário escolhe o alvo (UC11).
final class ImagemELinkCompartilhados extends ConteudoCompartilhado {
  const ImagemELinkCompartilhados({required this.imagem, required this.link});

  final ImagemEmMemoria imagem;
  final String link;

  @override
  void descartar() => imagem.descartar();
}

/// Texto sem um link que possa ser analisado. O texto em si não é guardado.
final class TextoSemLink extends ConteudoCompartilhado {
  const TextoSemLink();
}

/// Tipo não suportado, ou imagem que não pôde ser lida (UC11).
final class ConteudoNaoSuportado extends ConteudoCompartilhado {
  const ConteudoNaoSuportado();
}

final RegExp _endereco = RegExp(r'https?://\S+', caseSensitive: false);
final RegExp _pontuacaoFinal = RegExp(r'[.,;:!?)\]}>"]+$');

/// Encontra o link a analisar em um texto compartilhado. Devolve `null` se
/// não houver link, ou se houver mais de um, já que a análise é de um por vez.
///
/// O texto ao redor é ignorado: navegadores e aplicativos costumam mandar o
/// título da página junto com o endereço. Um texto de uma só palavra, como
/// `site.com.br`, é devolvido para que a análise de link decida se é válido.
String? extrairLink(String texto) {
  final limpo = texto.trim();
  final enderecos = _endereco.allMatches(limpo).toList();
  if (enderecos.length > 1) return null;
  if (enderecos.length == 1) {
    return enderecos.single.group(0)!.replaceFirst(_pontuacaoFinal, '');
  }
  return limpo.isEmpty || limpo.contains(RegExp(r'\s')) ? null : limpo;
}
