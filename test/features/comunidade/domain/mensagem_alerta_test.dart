import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/comunidade/domain/mensagem_alerta.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';

import '../../../support/fake_feed_repository.dart';

void main() {
  test('traz aviso de segurança, detalhes e a identidade do Phize (RF09)', () {
    final mensagem = mensagemDoAlerta(reporteDeTeste());

    expect(mensagem, startsWith('Alerta de golpe (Phize)'));
    expect(mensagem, contains('Falso parente pedindo Pix'));
    expect(mensagem, contains('Tipo: Falso contato'));
    expect(mensagem, contains('trocou de celular'));
    expect(mensagem, contains('2 pessoas relataram'));
    expect(mensagem, contains('canais oficiais'));
    expect(
      mensagem,
      endsWith('Enviado pelo Phize, app de prevenção a golpes.'),
    );
  });

  test('reporte pendente avisa que não foi revisado', () {
    expect(mensagemDoAlerta(reporteDeTeste()), contains('ainda não revisado'));
    expect(
      mensagemDoAlerta(reporteDeTeste(status: StatusReporte.aprovado)),
      isNot(contains('ainda não revisado')),
    );
  });

  test('reporte de link explica que o endereço não é mostrado', () {
    final mensagem = mensagemDoAlerta(
      reporteDeTeste(tipo: TipoReporte.link, relato: '', incidencias: 1),
    );
    expect(mensagem, contains('O Phize não mostra o endereço'));
    expect(mensagem, contains('1 pessoa relatou'));
    expect(mensagem, isNot(contains('\n\n\n')));
  });

  test('nunca usa "Seguro"', () {
    expect(mensagemDoAlerta(reporteDeTeste()), isNot(contains('eguro')));
  });
}
