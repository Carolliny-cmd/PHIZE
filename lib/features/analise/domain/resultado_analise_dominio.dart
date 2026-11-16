/// Saída da análise de anatomia de URL / typosquatting (RF03/UC03;
/// arquitetura, seção 4, item 4).
class ResultadoAnaliseDominio {
  const ResultadoAnaliseDominio({
    required this.entradaValida,
    this.dominioNormalizado,
    this.dominioRegistravel,
    this.typosquattingDetectado = false,
    this.marcaImitada,
    this.dominioEhCategoria = false,
  });

  /// `false` quando a entrada não é uma URL/domínio válido — os demais
  /// campos são então irrelevantes (`null`/`false`).
  final bool entradaValida;

  final String? dominioNormalizado;

  /// Parte registrável de [dominioNormalizado], sem subdomínios (ex.:
  /// "itau.com.br" para "www2.itau.com.br"). É o que a consulta RDAP
  /// recebe: a data de registro pertence ao domínio registrável, não a
  /// cada subdomínio. `null` quando [dominioEhCategoria] é `true`.
  final String? dominioRegistravel;

  /// `true` quando o endereço é a própria categoria do Registro.br (ex.:
  /// "gov.br", usado direto pelo governo federal em "www.gov.br/inss"). A
  /// categoria não tem dono individual nem data de registro, e ninguém
  /// consegue registrá-la como endereço novo.
  final bool dominioEhCategoria;
  final bool typosquattingDetectado;
  final String? marcaImitada;
}
