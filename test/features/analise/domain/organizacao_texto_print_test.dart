import 'package:flutter_test/flutter_test.dart';
import 'package:phize/shared/domain/organizacao_texto_print.dart';

const _largura = 1080.0;

LinhaReconhecida _linha(String texto, double esquerda, double topo,
        [double? direita]) =>
    LinhaReconhecida(
      texto: texto,
      esquerda: esquerda,
      topo: topo,
      direita: direita ?? esquerda + texto.length * 18,
      base: topo + 50,
    );

/// Print fictício na ordem embaralhada em que o ML Kit costuma devolver.
final _conversa = [
  _linha('15:29', 40, 32),
  _linha('+55 41 95432-1098', 243, 123),
  _linha('online', 231, 182),
  _linha('Olá, tia. Aqui é a Júlia, este é meu', 66, 624, 709),
  _linha('contato atual, perdi o aparelho', 66, 684, 661),
  _linha('Amanhã reponho.', 64, 1200, 407),
  _linha('Hoje', 512, 321, 570),
  _linha('Mensagem', 88, 2230, 298),
  _linha('Preciso quitar uma fatura até as 16h.', 68, 917, 752),
  _linha('15:23', 344, 1268, 408),
  _linha('Oi, quem fala?', 737, 446, 1010),
  _linha('87%', 892, 35, 956),
  _linha('15:20 /v', 902, 515, 1020),
];

void main() {
  test('ordena de cima para baixo e tira a interface do aplicativo', () {
    final texto = organizarTextoPrint(
      _conversa,
      largura: _largura,
      somenteRecebidas: false,
    );
    expect(texto.split('\n'), [
      '+55 41 95432-1098',
      'Oi, quem fala?',
      'Olá, tia. Aqui é a Júlia, este é meu',
      'contato atual, perdi o aparelho',
      'Preciso quitar uma fatura até as 16h.',
      'Amanhã reponho.',
    ]);
  });

  test('com somenteRecebidas, tira a resposta da pessoa e o cabeçalho', () {
    final texto = organizarTextoPrint(_conversa, largura: _largura);
    expect(texto.split('\n'), [
      'Olá, tia. Aqui é a Júlia, este é meu',
      'contato atual, perdi o aparelho',
      'Preciso quitar uma fatura até as 16h.',
      'Amanhã reponho.',
    ]);
  });

  test('sem linha alinhada à direita, não filtra pelo lado', () {
    // Ex.: print de e-mail ou de SMS recortado, sem resposta da pessoa.
    final linhas = [
      _linha('Banco: sua conta será bloqueada', 300, 100, 800),
      _linha('Acesse o endereço abaixo', 40, 160, 600),
    ];
    expect(
      organizarTextoPrint(linhas, largura: _largura),
      'Banco: sua conta será bloqueada\nAcesse o endereço abaixo',
    );
  });

  test('se o filtro deixaria o texto vazio, devolve as linhas ordenadas', () {
    final linhas = [
      _linha('Só a resposta da pessoa', 600, 100, 1040),
      _linha('outra linha no meio', 400, 50, 700),
    ];
    expect(
      organizarTextoPrint(linhas, largura: _largura),
      'outra linha no meio\nSó a resposta da pessoa',
    );
  });

  test('reconhece variações de horário, data e status como interface', () {
    final linhas = [
      for (final ruido in [
        '9:05',
        '21h30',
        '10:12 PM',
        '15:20 ✓✓',
        '16:21 V',
        '12/11/2026',
        'digitando...',
        'visto por último hoje às 10:00',
        'Ontem',
      ])
        _linha(ruido, 40, 10),
      _linha('Me passa o código', 40, 20, 400),
    ];
    expect(organizarTextoPrint(linhas, largura: _largura), 'Me passa o código');
  });

  test('não confunde valor ou frase curta com horário', () {
    final linhas = [
      _linha('R\$ 15,30', 40, 10, 200),
      _linha('às 15:30 te ligo', 40, 20, 400),
    ];
    expect(
      organizarTextoPrint(linhas, largura: _largura),
      'R\$ 15,30\nàs 15:30 te ligo',
    );
  });

  test('lista vazia devolve texto vazio', () {
    expect(organizarTextoPrint(const [], largura: _largura), '');
  });
}
