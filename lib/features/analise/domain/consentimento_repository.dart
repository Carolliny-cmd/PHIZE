/// Aumente este número quando o aviso de consentimento mudar de forma
/// relevante: quem aceitou uma versão anterior volta a vê-lo.
const int versaoConsentimentoAnalise = 1;

/// Consentimento para a análise de print (T33; RNF07, limitação declarada),
/// por usuário.
abstract class ConsentimentoRepository {
  Future<bool> aceito();

  Future<void> aceitar();

  Future<void> revogar();
}
