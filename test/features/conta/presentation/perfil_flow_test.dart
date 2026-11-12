import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phize/core/routing/app_router.dart';
import 'package:phize/core/routing/app_routes.dart';
import 'package:phize/features/analise/domain/caixa_compartilhamento.dart';
import 'package:phize/features/analise/domain/conteudo_compartilhado.dart';
import 'package:phize/features/auth/domain/auth_exception.dart';
import 'package:phize/features/conta/domain/conta_repository.dart';
import 'package:phize/features/conta/domain/exportacao_dados.dart';
import 'package:phize/features/conta/domain/nome_exibicao.dart';
import 'package:phize/features/conta/presentation/pages/perfil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/fake_consentimento_repository.dart';
import '../../../support/fake_conta_repository.dart';
import '../../../support/fake_historico_repository.dart';

const _senha = 'senha-de-teste';

Future<void> _abrir(
  WidgetTester tester, {
  required FakeContaRepository conta,
  FakeHistoricoRepository? historico,
  FakeCompartilhador? compartilhador,
  FakeAuthRepository? auth,
  String rota = AppRoutes.perfil,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        contaRepository: conta,
        historicoRepository: historico ?? FakeHistoricoRepository(),
        compartilhador: compartilhador ?? FakeCompartilhador(),
        authRepository: auth ?? FakeAuthRepository(),
      ),
      initialRoute: rota,
    ),
  );
  await tester.pumpAndSettle();
}

/// Os itens do perfil podem estar abaixo da área visível do teste.
Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = find.byKey(Key(chave));
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
}

Future<void> _abrirDialogo(WidgetTester tester) async {
  await _tocar(tester, 'perfil_excluir');
  await tester.pumpAndSettle();
}

Future<void> _confirmarExclusao(WidgetTester tester) async {
  await _abrirDialogo(tester);
  await tester.enterText(find.byKey(const Key('excluir_conta_senha')), _senha);
  await tester.tap(find.byKey(const Key('excluir_conta_confirmar')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Painel abre o Perfil', (tester) async {
    await _abrir(
      tester,
      conta: FakeContaRepository(),
      rota: AppRoutes.dashboard,
    );

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('perfil_exportar')), findsOneWidget);
    expect(find.byKey(const Key('perfil_excluir')), findsOneWidget);
  });

  testWidgets('exportar entrega arquivo com perfil e histórico', (
    tester,
  ) async {
    final compartilhador = FakeCompartilhador();
    await _abrir(
      tester,
      conta: FakeContaRepository(),
      compartilhador: compartilhador,
    );

    await _tocar(tester, 'perfil_exportar');
    await tester.pumpAndSettle();

    expect(compartilhador.nomeArquivo, nomeArquivoExportacao);
    final dados = jsonDecode(compartilhador.conteudo!) as Map<String, dynamic>;
    expect(dados['perfil']['email'], 'maria@exemplo.com');
  });

  testWidgets('a exportação pede o histórico ao servidor, não ao cache', (
    tester,
  ) async {
    final historico = FakeHistoricoRepository();
    await _abrir(tester, conta: FakeContaRepository(), historico: historico);

    await _tocar(tester, 'perfil_exportar');
    await tester.pumpAndSettle();

    expect(historico.ultimaLeituraSomenteServidor, isTrue);
  });

  testWidgets('a aba Perfil permite retirar o consentimento', (tester) async {
    final consentimento = FakeConsentimentoRepository();
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
          settings,
          contaRepository: FakeContaRepository(),
          historicoRepository: FakeHistoricoRepository(),
          authRepository: FakeAuthRepository(),
          consentimentoRepository: consentimento,
        ),
        initialRoute: AppRoutes.perfil,
      ),
    );
    await tester.pumpAndSettle();

    await _tocar(tester, 'perfil_privacidade');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('consentimento_recusar')));
    await tester.tap(find.byKey(const Key('consentimento_recusar')));
    await tester.pumpAndSettle();

    expect(consentimento.aceitou, isFalse);
  });

  testWidgets('sair encerra a sessão e leva ao login', (tester) async {
    final auth = FakeAuthRepository();
    await _abrir(tester, conta: FakeContaRepository(), auth: auth);

    await _tocar(tester, 'perfil_sair');
    await tester.pumpAndSettle();

    expect(auth.saiu, isTrue);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('falha antes da remoção avisa que nada foi apagado e não '
      'bloqueia a conta', (tester) async {
    final conta = FakeContaRepository()..erroExclusao = StateError('sem rede');
    await _abrir(tester, conta: conta);

    await _confirmarExclusao(tester);

    expect(find.textContaining('nada foi apagado'), findsOneWidget);
    expect(find.byKey(const Key('perfil_excluir')), findsOneWidget);
    expect(find.byKey(const Key('exclusao_pendente_concluir')), findsNothing);
  });

  testWidgets('falha ao exportar mostra mensagem e libera a tela', (
    tester,
  ) async {
    final compartilhador = FakeCompartilhador();
    await _abrir(
      tester,
      conta: FakeContaRepository()..falhaPerfil = true,
      compartilhador: compartilhador,
    );

    await _tocar(tester, 'perfil_exportar');
    await tester.pumpAndSettle();

    expect(compartilhador.conteudo, isNull);
    expect(find.byKey(const Key('perfil_erro')), findsOneWidget);
    final botao = tester.widget<OutlinedButton>(
      find.byWidgetPredicate((w) => w is OutlinedButton).first,
    );
    expect(botao.onPressed, isNotNull);
  });

  testWidgets('aviso de irreversibilidade e cancelamento aborta', (
    tester,
  ) async {
    final conta = FakeContaRepository();
    await _abrir(tester, conta: conta);

    await _abrirDialogo(tester);
    expect(find.textContaining('não pode ser desfeita'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(conta.exclusoes, 0);
    expect(find.byKey(const Key('perfil_excluir')), findsOneWidget);
  });

  testWidgets('sem senha, a exclusão não começa', (tester) async {
    final conta = FakeContaRepository();
    await _abrir(tester, conta: conta);

    await _abrirDialogo(tester);
    await tester.tap(find.byKey(const Key('excluir_conta_confirmar')));
    await tester.pumpAndSettle();

    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(conta.exclusoes, 0);
  });

  testWidgets('exclusão concluída volta ao login sem caminho de retorno', (
    tester,
  ) async {
    final conta = FakeContaRepository();
    await _abrir(tester, conta: conta);

    await _confirmarExclusao(tester);

    expect(conta.senhaRecebida, _senha);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.text('Sua conta foi excluída.'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('conta do Google confirma a exclusão sem senha', (tester) async {
    final conta = FakeContaRepository()..exigeSenha = false;
    await _abrir(tester, conta: conta);

    await _abrirDialogo(tester);
    expect(find.byKey(const Key('excluir_conta_senha')), findsNothing);
    await tester.tap(find.byKey(const Key('excluir_conta_confirmar')));
    await tester.pumpAndSettle();

    expect(conta.exclusoes, 1);
    expect(conta.senhaRecebida, isNull);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
  });

  testWidgets('entrar com Google abre o Painel', (tester) async {
    final auth = FakeAuthRepository();
    await _abrir(
      tester,
      conta: FakeContaRepository(),
      auth: auth,
      rota: AppRoutes.login,
    );

    await tester.tap(find.byKey(const Key('login_google')));
    await tester.pumpAndSettle();

    expect(auth.entradasGoogle, 1);
    expect(find.text('Recebeu algo estranho?'), findsOneWidget);
  });

  testWidgets('desistir do Google permanece no login, sem erro', (tester) async {
    final auth = FakeAuthRepository()..resultadoGoogle = null;
    await _abrir(
      tester,
      conta: FakeContaRepository(),
      auth: auth,
      rota: AppRoutes.login,
    );

    await tester.tap(find.byKey(const Key('login_google')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email')), findsOneWidget);
    final botao = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('login_google')),
    );
    expect(botao.onPressed, isNotNull);
  });

  testWidgets('falha do Google mostra a mensagem', (tester) async {
    final auth = FakeAuthRepository()
      ..erroGoogle = const AuthException('Falha simulada.');
    await _abrir(
      tester,
      conta: FakeContaRepository(),
      auth: auth,
      rota: AppRoutes.login,
    );

    await tester.tap(find.byKey(const Key('login_google')));
    await tester.pumpAndSettle();

    expect(find.text('Falha simulada.'), findsOneWidget);
  });

  testWidgets('login com Google respeita a exclusão pendente', (tester) async {
    await _abrir(
      tester,
      conta: FakeContaRepository(pendente: true),
      rota: AppRoutes.login,
    );

    await tester.tap(find.byKey(const Key('login_google')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exclusao_pendente_concluir')), findsOneWidget);
  });

  testWidgets('senha incorreta mostra o erro e fica na tela', (tester) async {
    final conta = FakeContaRepository()
      ..erroExclusao = const AuthException('Senha incorreta.');
    await _abrir(tester, conta: conta);

    await _confirmarExclusao(tester);

    expect(find.text('Senha incorreta.'), findsOneWidget);
    expect(find.byKey(const Key('perfil_excluir')), findsOneWidget);
  });

  testWidgets('falha parcial bloqueia a conta até a exclusão terminar', (
    tester,
  ) async {
    final conta = FakeContaRepository()
      ..erroExclusao = const ExclusaoIncompletaException();
    await _abrir(tester, conta: conta);

    await _confirmarExclusao(tester);

    expect(find.byKey(const Key('exclusao_pendente_concluir')), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exclusao_pendente_concluir')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('exclusao_pendente_senha')),
      _senha,
    );
    await tester.tap(find.byKey(const Key('exclusao_pendente_concluir')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exclusao_pendente_erro')), findsOneWidget);

    conta.erroExclusao = null;
    await tester.tap(find.byKey(const Key('exclusao_pendente_concluir')));
    await tester.pumpAndSettle();

    expect(conta.exclusoes, 3);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
  });

  testWidgets('login com exclusão pendente vai direto ao bloqueio', (
    tester,
  ) async {
    await _abrir(
      tester,
      conta: FakeContaRepository(pendente: true),
      rota: AppRoutes.login,
    );

    await tester.enterText(
      find.byKey(const Key('login_email')),
      'maria@exemplo.com',
    );
    await tester.enterText(find.byKey(const Key('login_senha')), _senha);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exclusao_pendente_concluir')), findsOneWidget);
    expect(find.text('Perfil'), findsNothing);
  });

  group('conteúdo compartilhado sem sessão (RF10)', () {
    Future<void> abrirLogin(WidgetTester tester, {bool pendente = false}) async {
      final caixa = CaixaCompartilhamento()
        ..guardar(const TextoSemLink());
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
            settings,
            contaRepository: FakeContaRepository(pendente: pendente),
            authRepository: FakeAuthRepository(),
            caixaCompartilhamento: caixa,
          ),
          initialRoute: AppRoutes.login,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login_conteudo_aguardando')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'maria@exemplo.com',
      );
      await tester.enterText(find.byKey(const Key('login_senha')), _senha);
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();
    }

    testWidgets('depois do login, a análise abre sozinha', (tester) async {
      await abrirLogin(tester);

      expect(find.byKey(const Key('compartilhado_mensagem')), findsOneWidget);
    });

    testWidgets('conta com exclusão pendente fica no bloqueio', (tester) async {
      await abrirLogin(tester, pendente: true);

      expect(find.byKey(const Key('exclusao_pendente_concluir')), findsOneWidget);
      expect(find.byKey(const Key('compartilhado_mensagem')), findsNothing);
    });
  });

  testWidgets('do bloqueio é possível sair', (tester) async {
    final auth = FakeAuthRepository();
    await _abrir(
      tester,
      conta: FakeContaRepository(pendente: true),
      auth: auth,
      rota: AppRoutes.exclusaoPendente,
    );

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(auth.saiu, isTrue);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
  });

  group('identificação (RF14)', () {
    testWidgets('mostra o e-mail verificado e a forma de login', (
      tester,
    ) async {
      await _abrir(tester, conta: FakeContaRepository());

      expect(find.text('maria@exemplo.com'), findsWidgets);
      expect(find.byKey(const Key('perfil_email_verificado')), findsOneWidget);
      expect(find.text('E-mail e senha'), findsOneWidget);
    });

    testWidgets('conta do Google com e-mail não verificado', (tester) async {
      final conta = FakeContaRepository()
        ..identidade = const IdentidadeConta(
          email: 'jose@exemplo.com',
          emailVerificado: false,
          entraComSenha: false,
          entraComGoogle: true,
        );
      await _abrir(tester, conta: conta);

      expect(find.byKey(const Key('perfil_email_pendente')), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('salvar o nome grava a versão normalizada e mostra no topo', (
      tester,
    ) async {
      final conta = FakeContaRepository();
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_nome');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('editar_nome_campo')),
        '  Maria   da Silva ',
      );
      await tester.tap(find.byKey(const Key('editar_nome_salvar')));
      await tester.pumpAndSettle();

      expect(conta.nomeExibicao, 'Maria da Silva');
      expect(
        tester.widget<Text>(find.byKey(const Key('perfil_cabecalho_nome'))).data,
        'Maria da Silva',
      );
      expect(find.text('Nome salvo.'), findsOneWidget);
    });

    testWidgets('o nome já gravado aparece ao abrir e pode ser removido', (
      tester,
    ) async {
      final conta = FakeContaRepository()..nomeExibicao = 'Vó Neuza';
      await _abrir(tester, conta: conta);
      expect(find.text('Vó Neuza'), findsWidgets);

      await _tocar(tester, 'perfil_nome');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editar_nome_remover')));
      await tester.pumpAndSettle();

      expect(conta.nomeExibicao, isNull);
      expect(find.text('Vó Neuza'), findsNothing);
      expect(find.text('Nome removido.'), findsOneWidget);
    });

    testWidgets('campo vazio salvo equivale a remover o nome', (tester) async {
      final conta = FakeContaRepository()..nomeExibicao = 'Maria';
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_nome');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editar_nome_campo')), '  ');
      await tester.tap(find.byKey(const Key('editar_nome_salvar')));
      await tester.pumpAndSettle();

      expect(conta.nomeExibicao, isNull);
    });

    testWidgets('o campo não aceita mais que o limite', (tester) async {
      await _abrir(tester, conta: FakeContaRepository());

      await _tocar(tester, 'perfil_nome');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('editar_nome_campo')),
        'a' * (limiteNomeExibicao + 10),
      );
      await tester.pump();

      final campo = tester.widget<TextField>(
        find.byKey(const Key('editar_nome_campo')),
      );
      expect(campo.controller!.text.length, limiteNomeExibicao);
    });

    testWidgets('cancelar não grava nada', (tester) async {
      final conta = FakeContaRepository()..nomeExibicao = 'Maria';
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_nome');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editar_nome_campo')), 'Outro');
      await tester.tap(find.byKey(const Key('editar_nome_cancelar')));
      await tester.pumpAndSettle();

      expect(conta.nomeExibicao, 'Maria');
    });

    testWidgets('falha ao salvar mostra o aviso e mantém o nome anterior', (
      tester,
    ) async {
      final conta = FakeContaRepository()
        ..nomeExibicao = 'Maria'
        ..falhaSalvarNome = true;
      await _abrir(tester, conta: conta);

      await _tocar(tester, 'perfil_nome');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editar_nome_campo')), 'Outro');
      await tester.tap(find.byKey(const Key('editar_nome_salvar')));
      await tester.pumpAndSettle();

      expect(find.text(PerfilPage.mensagemFalhaNome), findsOneWidget);
      expect(find.text('Outro'), findsNothing);
    });

    testWidgets('a exportação inclui o nome de exibição', (tester) async {
      final compartilhador = FakeCompartilhador();
      await _abrir(
        tester,
        conta: FakeContaRepository()..nomeExibicao = 'Maria',
        compartilhador: compartilhador,
      );

      await _tocar(tester, 'perfil_exportar');
      await tester.pumpAndSettle();

      final dados = jsonDecode(compartilhador.conteudo!) as Map<String, dynamic>;
      expect(dados['perfil']['nomeExibicao'], 'Maria');
    });
  });
}
