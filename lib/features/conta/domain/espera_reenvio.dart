/// Espera mínima entre dois pedidos de reenvio do e-mail de verificação
/// (RF14). O Firebase Authentication também limita os envios do lado do
/// servidor; esta espera só evita toques repetidos.
const Duration esperaReenvioVerificacao = Duration(seconds: 60);

/// Lembra, enquanto o app está aberto, quando foi o último reenvio.
class EsperaReenvio {
  EsperaReenvio({DateTime Function()? relogio})
    : _relogio = relogio ?? DateTime.now;

  /// Compartilhada pelas telas, para a espera continuar valendo ao sair e
  /// voltar ao perfil.
  static final EsperaReenvio global = EsperaReenvio();

  final DateTime Function() _relogio;
  DateTime? _ultimoEnvio;

  /// Quanto falta para poder pedir de novo; zero quando já pode.
  Duration get restante {
    final ultimo = _ultimoEnvio;
    if (ultimo == null) return Duration.zero;
    final falta = esperaReenvioVerificacao - _relogio().difference(ultimo);
    return falta.isNegative ? Duration.zero : falta;
  }

  void registrarEnvio() => _ultimoEnvio = _relogio();
}
