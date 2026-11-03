import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/conta/domain/conta_repository.dart';
import 'package:phize/features/conta/domain/exclusao_conta.dart';

void main() {
  late List<String> etapas;

  Future<void> executar({String? falhaEm, Object? erro}) {
    Future<void> etapa(String nome) async {
      if (nome == falhaEm) throw erro ?? StateError('falha simulada');
      etapas.add(nome);
    }

    return executarExclusaoConta<String>(
      confirmarSenha: () => etapa('senha'),
      lerDocumentos: () async {
        await etapa('ler');
        return 'documentos';
      },
      registrarPendencia: () => etapa('pendencia'),
      removerDocumentos: (documentos) => etapa('remover $documentos'),
      removerCredencial: () => etapa('credencial'),
      concluir: () => etapa('concluir'),
    );
  }

  setUp(() => etapas = []);

  test('segue a ordem, com a credencial por último', () async {
    await executar();

    expect(etapas, [
      'senha',
      'ler',
      'pendencia',
      'remover documentos',
      'credencial',
      'concluir',
    ]);
  });

  test('senha errada não lê nem apaga nada', () async {
    await expectLater(
      executar(falhaEm: 'senha', erro: const AuthException('Senha incorreta.')),
      throwsA(isA<AuthException>()),
    );

    expect(etapas, isEmpty);
  });

  test('falha ao ler os documentos não bloqueia a conta', () async {
    await expectLater(
      executar(falhaEm: 'ler'),
      throwsA(isNot(isA<ExclusaoIncompletaException>())),
    );

    expect(etapas, ['senha']);
  });

  test('falha ao registrar a pendência não apaga nada', () async {
    await expectLater(
      executar(falhaEm: 'pendencia'),
      throwsA(isNot(isA<ExclusaoIncompletaException>())),
    );

    expect(etapas, ['senha', 'ler']);
  });

  test(
    'falha na remoção dos documentos mantém a pendência e a credencial',
    () async {
      await expectLater(
        executar(falhaEm: 'remover documentos'),
        throwsA(isA<ExclusaoIncompletaException>()),
      );

      expect(etapas, ['senha', 'ler', 'pendencia']);
    },
  );

  test('falha na remoção da credencial mantém a pendência', () async {
    await expectLater(
      executar(falhaEm: 'credencial'),
      throwsA(isA<ExclusaoIncompletaException>()),
    );

    expect(etapas, isNot(contains('concluir')));
  });

  test(
    'falha ao limpar a pendência não contradiz a conta já removida',
    () async {
      await executar(falhaEm: 'concluir');

      expect(etapas.last, 'credencial');
    },
  );
}
