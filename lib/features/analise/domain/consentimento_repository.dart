/// Aumente este número quando o aviso de consentimento mudar de forma
/// relevante: quem aceitou uma versão anterior volta a vê-lo.
///
/// Versão 2 (2026-11-12): aviso de que o nível gratuito do Gemini pode usar
/// o texto e de que só conversas de teste devem ser analisadas (RNF07,
/// limitação de escopo acadêmico).
const int versaoConsentimentoAnalise = 2;

/// Consentimento para a análise de print (T33; RNF07, limitação declarada),
/// por usuário.
abstract class ConsentimentoRepository {
  Future<bool> aceito();

  Future<void> aceitar();

  Future<void> revogar();
}
