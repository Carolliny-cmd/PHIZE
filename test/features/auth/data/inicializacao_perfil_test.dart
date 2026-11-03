import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/data/inicializacao_perfil.dart';
import 'package:phize/features/auth/domain/auth_exception.dart';

void main() {
  const limite = Duration(milliseconds: 20);

  final falhaDeCadastro = isA<AuthException>().having(
    (e) => e.mensagem,
    'mensagem',
    mensagemFalhaInicializacaoPerfil,
  );

  test('gravação concluída não desfaz a conta', () async {
    var desfeita = false;
    await inicializarPerfilOuDesfazer(
      gravarPerfil: () async {},
      desfazerConta: () async => desfeita = true,
      limite: limite,
    );
    expect(desfeita, isFalse);
  });

  test('servidor que não responde encerra com erro em vez de esperar '
      'para sempre', () async {
    var desfeita = false;
    await expectLater(
      inicializarPerfilOuDesfazer(
        gravarPerfil: () => Completer<void>().future,
        desfazerConta: () async => desfeita = true,
        limite: limite,
      ),
      throwsA(falhaDeCadastro),
    );
    expect(desfeita, isTrue);
  });

  test('gravação recusada desfaz a conta e avisa o usuário', () async {
    var desfeita = false;
    await expectLater(
      inicializarPerfilOuDesfazer(
        gravarPerfil: () async => throw Exception('permission-denied'),
        desfazerConta: () async => desfeita = true,
        limite: limite,
      ),
      throwsA(falhaDeCadastro),
    );
    expect(desfeita, isTrue);
  });

  test('falha ao desfazer a conta mantém a mesma mensagem', () async {
    await expectLater(
      inicializarPerfilOuDesfazer(
        gravarPerfil: () async => throw Exception('unavailable'),
        desfazerConta: () async => throw Exception('network-request-failed'),
        limite: limite,
      ),
      throwsA(falhaDeCadastro),
    );
  });

  test('remoção da conta que também não responde não prende a tela', () async {
    await expectLater(
      inicializarPerfilOuDesfazer(
        gravarPerfil: () => Completer<void>().future,
        desfazerConta: () => Completer<void>().future,
        limite: limite,
      ),
      throwsA(falhaDeCadastro),
    );
  });
}
