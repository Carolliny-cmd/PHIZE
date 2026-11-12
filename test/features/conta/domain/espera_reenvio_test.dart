import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/conta/domain/espera_reenvio.dart';

void main() {
  test('sem envio anterior, pode enviar', () {
    expect(EsperaReenvio().restante, Duration.zero);
  });

  test('depois de enviar, espera o intervalo inteiro', () {
    var agora = DateTime(2026, 11, 12, 10);
    final espera = EsperaReenvio(relogio: () => agora)..registrarEnvio();

    expect(espera.restante, esperaReenvioVerificacao);

    agora = agora.add(const Duration(seconds: 45));
    expect(espera.restante, esperaReenvioVerificacao - const Duration(seconds: 45));

    agora = agora.add(esperaReenvioVerificacao);
    expect(espera.restante, Duration.zero);
  });
}
