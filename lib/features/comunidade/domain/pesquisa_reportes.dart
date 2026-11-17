import '../../../shared/domain/normalizacao_url.dart';
import 'palavras_busca.dart';
import 'preparacao_reporte.dart';

/// O que a pessoa digitou na pesquisa da comunidade (RF15, UC08), já
/// convertido no aparelho: um link vira só a hash (o endereço não sai do
/// aparelho), e o texto vira as palavras de busca.
sealed class ConsultaPesquisa {
  const ConsultaPesquisa();
}

class ConsultaPorLink extends ConsultaPesquisa {
  const ConsultaPorLink(this.hash);

  final String hash;
}

class ConsultaPorPalavras extends ConsultaPesquisa {
  const ConsultaPorPalavras(this.palavras);

  final List<String> palavras;
}

/// O Firestore aceita até 10 valores por consulta `array-contains-any`.
const int maximoPalavrasPesquisa = 10;

/// Interpreta a pesquisa. Um texto sem espaços que seja um endereço válido
/// é tratado como link, com a mesma normalização e hash do reporte (RF05).
/// `null` se não sobrar nada para pesquisar (palavras de menos de 3 letras).
ConsultaPesquisa? interpretarPesquisa(String entrada) {
  final texto = entrada.trim();
  if (texto.isEmpty) return null;
  if (!texto.contains(RegExp(r'\s')) && normalizarDominio(texto) != null) {
    final hash = hashDoLink(texto);
    if (hash != null) return ConsultaPorLink(hash);
  }
  final palavras = palavrasDeBusca([texto]);
  if (palavras.isEmpty) return null;
  return ConsultaPorPalavras(palavras.take(maximoPalavrasPesquisa).toList());
}
