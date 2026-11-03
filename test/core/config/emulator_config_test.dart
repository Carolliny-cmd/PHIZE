import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/config/emulator_config.dart';

void main() {
  test('sem variáveis o app usa Auth e Firestore de produção', () {
    final emuladores = EmulatorConfig.emuladores;
    expect(emuladores.auth, isNull);
    expect(emuladores.firestore, isNull);
  });

  test('valor vazio resulta em produção', () {
    expect(EmulatorConfig.interpretar(''), isNull);
    expect(EmulatorConfig.interpretar('   '), isNull);
  });

  test('host:porta do emulador Android', () {
    final endereco = EmulatorConfig.interpretar('10.0.2.2:9099')!;
    expect(endereco.host, '10.0.2.2');
    expect(endereco.porta, 9099);
  });

  test('host:porta do navegador', () {
    final endereco = EmulatorConfig.interpretar('127.0.0.1:9099')!;
    expect(endereco.host, '127.0.0.1');
    expect(endereco.porta, 9099);
  });

  test('valor malformado é recusado em vez de cair em produção', () {
    for (final valor in [
      '10.0.2.2',
      ':9099',
      '10.0.2.2:',
      '10.0.2.2:porta',
      '10.0.2.2:0',
      '10.0.2.2:70000',
    ]) {
      expect(
        () => EmulatorConfig.interpretar(valor),
        throwsFormatException,
        reason: valor,
      );
    }
  });

  test('Auth e Firestore emulados juntos', () {
    final emuladores = EmulatorConfig.resolver(
      '10.0.2.2:9099',
      '10.0.2.2:8085',
    );
    expect(emuladores.auth!.porta, 9099);
    expect(emuladores.firestore!.host, '10.0.2.2');
    expect(emuladores.firestore!.porta, 8085);
  });

  test('só um dos dois emulados é recusado', () {
    expect(
      () => EmulatorConfig.resolver('10.0.2.2:9099', ''),
      throwsFormatException,
    );
    expect(
      () => EmulatorConfig.resolver('', '10.0.2.2:8085'),
      throwsFormatException,
    );
  });

  test('a mensagem de erro cita a variável malformada', () {
    expect(
      () => EmulatorConfig.resolver('10.0.2.2:9099', '10.0.2.2'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('PHIZE_FIRESTORE_EMULATOR'),
        ),
      ),
    );
  });
}
