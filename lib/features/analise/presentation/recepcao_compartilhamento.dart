import '../domain/caixa_compartilhamento.dart';
import '../domain/conteudo_compartilhado.dart';

/// Decide o que fazer com um conteúdo que acabou de chegar (UC11): abre a
/// análise se houver sessão liberada; caso contrário, ele fica na caixa até
/// o login terminar (RF10).
class RecepcaoCompartilhamento {
  RecepcaoCompartilhamento({
    required this.caixa,
    required this.sessaoAtiva,
    required this.exclusaoPendente,
    required this.abrirAnalise,
  });

  final CaixaCompartilhamento caixa;
  final bool Function() sessaoAtiva;
  final Future<bool> Function() exclusaoPendente;
  final void Function() abrirAnalise;

  Future<void> receber(ConteudoCompartilhado conteudo) async {
    caixa.guardar(conteudo);
    if (!sessaoAtiva()) return;

    // Conta com exclusão pendente fica bloqueada (UC12): a análise não pode
    // abrir por cima da tela de bloqueio.
    final bool bloqueada;
    try {
      bloqueada = await exclusaoPendente();
    } catch (_) {
      return;
    }
    if (!bloqueada) abrirAnalise();
  }
}
