import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/receptor_compartilhamento.dart';
import 'package:phize/features/analise/domain/caixa_compartilhamento.dart';
import 'package:phize/features/analise/domain/conteudo_compartilhado.dart';
import 'package:phize/shared/domain/imagem_em_memoria.dart';
import 'package:phize/features/analise/presentation/recepcao_compartilhamento.dart';

void main() {
  group('extrairLink', () {
    test('endereço sozinho', () {
      expect(extrairLink(' https://site.com.br/a?b=1 '), 'https://site.com.br/a?b=1');
    });

    test('endereço com título, como mandam os navegadores', () {
      expect(extrairLink('Promoção imperdível\nhttps://site.com.br/oferta'), 'https://site.com.br/oferta');
    });

    test('tira a pontuação colada ao fim do endereço', () {
      expect(extrairLink('Olha isso (https://site.com.br/a).'), 'https://site.com.br/a');
    });

    test('domínio sem protocolo', () {
      expect(extrairLink('site.com.br'), 'site.com.br');
    });

    test('mensagem sem link', () {
      expect(extrairLink('Mãe, troquei de número, preciso de um Pix'), isNull);
    });

    test('mais de um link', () {
      expect(extrairLink('https://a.com.br e https://b.com.br'), isNull);
    });

    test('texto vazio', () {
      expect(extrairLink('   '), isNull);
    });
  });

  group('conteudoDeMensagem', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('imagem', () {
      expect(conteudoDeMensagem({'imagem': bytes}), isA<ImagemCompartilhada>());
    });

    test('imagem com legenda sem link continua sendo só imagem', () {
      expect(
        conteudoDeMensagem({'imagem': bytes, 'texto': 'Olha isso'}),
        isA<ImagemCompartilhada>(),
      );
    });

    test('imagem com link pede escolha', () {
      expect(
        conteudoDeMensagem({'imagem': bytes, 'texto': 'https://site.com.br'}),
        isA<ImagemELinkCompartilhados>(),
      );
    });

    test('link', () {
      final conteudo = conteudoDeMensagem({'texto': 'https://site.com.br'});
      expect((conteudo as LinkCompartilhado).link, 'https://site.com.br');
    });

    test('texto sem link não carrega o texto', () {
      expect(conteudoDeMensagem({'texto': 'Oi, tudo bem?'}), isA<TextoSemLink>());
    });

    test('não suportado', () {
      expect(conteudoDeMensagem({'naoSuportado': true}), isA<ConteudoNaoSuportado>());
      expect(conteudoDeMensagem({'imagem': Uint8List(0)}), isA<ConteudoNaoSuportado>());
    });
  });

  group('CaixaCompartilhamento', () {
    ImagemCompartilhada imagem() =>
        ImagemCompartilhada(ImagemEmMemoria(Uint8List.fromList([1, 2])));

    test('entrega uma única vez', () {
      final caixa = CaixaCompartilhamento();
      final conteudo = imagem();
      caixa.guardar(conteudo);

      expect(caixa.temPendente, isTrue);
      expect(caixa.retirar(), same(conteudo));
      expect(caixa.temPendente, isFalse);
      expect(caixa.retirar(), isNull);
    });

    test('um conteúdo novo descarta o anterior da memória', () {
      final caixa = CaixaCompartilhamento();
      final anterior = imagem();
      caixa.guardar(anterior);

      caixa.guardar(imagem());

      expect(anterior.imagem.descartada, isTrue);
    });
  });

  group('RecepcaoCompartilhamento', () {
    late CaixaCompartilhamento caixa;
    late int aberturas;

    RecepcaoCompartilhamento recepcao({
      bool sessao = true,
      Future<bool> Function()? exclusaoPendente,
    }) => RecepcaoCompartilhamento(
      caixa: caixa,
      sessaoAtiva: () => sessao,
      exclusaoPendente: exclusaoPendente ?? () async => false,
      abrirAnalise: () => aberturas++,
    );

    setUp(() {
      caixa = CaixaCompartilhamento();
      aberturas = 0;
    });

    test('com sessão, abre a análise', () async {
      await recepcao().receber(const LinkCompartilhado('site.com.br'));

      expect(aberturas, 1);
      expect(caixa.temPendente, isTrue);
    });

    test('sem sessão, o conteúdo espera o login em memória', () async {
      await recepcao(sessao: false).receber(const LinkCompartilhado('site.com.br'));

      expect(aberturas, 0);
      expect(caixa.temPendente, isTrue);
    });

    test('conta com exclusão pendente não abre a análise', () async {
      await recepcao(
        exclusaoPendente: () async => true,
      ).receber(const LinkCompartilhado('site.com.br'));

      expect(aberturas, 0);
    });

    test('falha ao conferir a exclusão pendente não abre a análise', () async {
      await recepcao(
        exclusaoPendente: () async => throw StateError('falha simulada'),
      ).receber(const LinkCompartilhado('site.com.br'));

      expect(aberturas, 0);
    });
  });
}
