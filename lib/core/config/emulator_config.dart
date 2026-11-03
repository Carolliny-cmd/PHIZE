/// Endereços dos emuladores do Firebase Auth e do Cloud Firestore, usados só
/// em desenvolvimento (docs/emulador-local.md).
///
/// Sem `--dart-define`, o app usa o Firebase de produção. Com o emulador de
/// Auth ativo, as Functions emuladas só aceitam tokens emitidos por ele, então
/// o app precisa autenticar no mesmo emulador. O Firestore de produção também
/// recusa esses tokens, e o cadastro (que grava `users/{uid}`) ficaria
/// tentando de novo sem fim; por isso Auth e Firestore emulados andam juntos:
///
/// ```
/// flutter run --dart-define=PHIZE_AUTH_EMULATOR=10.0.2.2:9099 --dart-define=PHIZE_FIRESTORE_EMULATOR=10.0.2.2:8085
/// ```
///
/// O host muda por plataforma (`10.0.2.2` no emulador Android, `127.0.0.1`
/// no navegador) e é decidido pelo valor passado, como em
/// `PHIZE_FUNCTIONS_URL`.
class EmulatorConfig {
  EmulatorConfig._();

  static const String _auth = String.fromEnvironment('PHIZE_AUTH_EMULATOR');
  static const String _firestore = String.fromEnvironment(
    'PHIZE_FIRESTORE_EMULATOR',
  );

  /// Emuladores informados na compilação; [EmuladoresFirebase.auth] e
  /// [EmuladoresFirebase.firestore] nulos significam produção.
  static EmuladoresFirebase get emuladores => resolver(_auth, _firestore);

  /// Interpreta as duas variáveis e recusa a combinação em que só uma delas
  /// foi informada: token de um ambiente nunca é aceito pelo outro.
  static EmuladoresFirebase resolver(String auth, String firestore) {
    final enderecoAuth = interpretar(auth, variavel: 'PHIZE_AUTH_EMULATOR');
    final enderecoFirestore = interpretar(
      firestore,
      variavel: 'PHIZE_FIRESTORE_EMULATOR',
    );
    if ((enderecoAuth == null) != (enderecoFirestore == null)) {
      throw const FormatException(
        'PHIZE_AUTH_EMULATOR e PHIZE_FIRESTORE_EMULATOR devem ser informados '
        'juntos: o Firestore só aceita tokens do mesmo ambiente do Auth.',
      );
    }
    return EmuladoresFirebase(enderecoAuth, enderecoFirestore);
  }

  /// Converte `host:porta` no endereço do emulador. Vazio resulta em `null`;
  /// valor malformado lança [FormatException], para não cair em produção
  /// silenciosamente quando a intenção era usar o emulador.
  static EnderecoEmulador? interpretar(
    String valor, {
    String variavel = 'PHIZE_AUTH_EMULATOR',
  }) {
    final texto = valor.trim();
    if (texto.isEmpty) return null;
    final separador = texto.lastIndexOf(':');
    final host = separador > 0 ? texto.substring(0, separador) : '';
    final porta = separador > 0
        ? int.tryParse(texto.substring(separador + 1))
        : null;
    if (host.isEmpty || porta == null || porta <= 0 || porta > 65535) {
      throw FormatException(
        '$variavel deve ter o formato host:porta (ex.: 10.0.2.2:9099).',
        valor,
      );
    }
    return EnderecoEmulador(host, porta);
  }
}

class EmuladoresFirebase {
  const EmuladoresFirebase(this.auth, this.firestore);

  final EnderecoEmulador? auth;
  final EnderecoEmulador? firestore;
}

class EnderecoEmulador {
  const EnderecoEmulador(this.host, this.porta);

  final String host;
  final int porta;
}
