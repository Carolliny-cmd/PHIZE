import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/palavras_busca.dart';
import 'package:phize/features/comunidade/domain/preparacao_reporte.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

/// Conteúdo fictício. Os números abaixo são formatos de teste, não dados
/// reais.
void main() {
  NovoReporte pronto(PreparacaoReporte p) => (p as ReportePronto).reporte;
  MotivoRecusaReporte recusa(PreparacaoReporte p) =>
      (p as ReporteRecusado).motivo;

  group('link (RF05; arquitetura, 5.5)', () {
    test('vira hash SHA-256 do domínio, sem o link em texto puro', () {
      final r = pronto(
        prepararReporte(
          tipo: TipoReporte.link,
          titulo: 'Entrega com taxa',
          relato: '',
          categoria: CategoriaAmeaca.cobrancaOuBoletoFalso,
          link: 'https://entrega-taxa.example/pagar?id=1',
        ),
      );
      expect(r.hashLink, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(r.titulo, isNot(contains('example')));
    });

    test('variações do mesmo endereço dão a mesma hash', () {
      final hashes = {
        hashDoLink('entrega-taxa.example'),
        hashDoLink('https://www.entrega-taxa.example/pagar'),
        hashDoLink('http://ENTREGA-TAXA.example/?utm=1#topo'),
      };
      expect(hashes, hasLength(1));
      expect(hashDoLink('outra-loja.example'), isNot(hashes.single));
    });

    test('entrada que não é link é recusada', () {
      expect(
        recusa(
          prepararReporte(
            tipo: TipoReporte.link,
            titulo: 'Título qualquer',
            relato: '',
            categoria: CategoriaAmeaca.outroGolpe,
            link: 'não é link',
          ),
        ),
        MotivoRecusaReporte.linkInvalido,
      );
    });

    for (final oficial in [
      'https://www.itau.com.br/conta',
      'internetbanking.caixa.gov.br',
      'https://www.gov.br/inss',
    ]) {
      test('domínio oficial é recusado: $oficial', () {
        expect(
          recusa(
            prepararReporte(
              tipo: TipoReporte.link,
              titulo: 'Título qualquer',
              relato: '',
              categoria: CategoriaAmeaca.outroGolpe,
              link: oficial,
            ),
          ),
          MotivoRecusaReporte.dominioOficial,
        );
      });
    }

    test('imitação de marca não é domínio oficial', () {
      expect(dominioOficial('itau-seguranca.com.br'), isFalse);
      expect(dominioOficial('www.tse.jus.br'), isFalse);
    });
  });

  group('texto público (RNF07, etapa 1)', () {
    test('relato tem dados estruturados mascarados e links escondidos', () {
      final r = pronto(
        prepararReporte(
          tipo: TipoReporte.relato,
          titulo: 'Pediram meu CPF 123.456.789-09',
          relato:
              'Ligaram do (11) 98765-4321 e mandaram https://golpe.example/x '
              'e o site conta-segura.example.',
          categoria: CategoriaAmeaca.falsaCentralOuInstituicao,
        ),
      );
      expect(r.titulo, 'Pediram meu CPF [CPF]');
      expect(r.relato, contains('[TELEFONE]'));
      expect(r.relato, isNot(contains('98765')));
      expect(r.relato, isNot(contains('golpe.example')));
      expect(r.relato, isNot(contains('conta-segura')));
      expect('[LINK]'.allMatches(r.relato), hasLength(2));
      expect(r.hashLink, isNull);
    });

    test('título curto e relato vazio são recusados', () {
      expect(
        recusa(
          prepararReporte(
            tipo: TipoReporte.relato,
            titulo: 'ab',
            relato: 'Algo aconteceu.',
            categoria: CategoriaAmeaca.outroGolpe,
          ),
        ),
        MotivoRecusaReporte.tituloCurto,
      );
      expect(
        recusa(
          prepararReporte(
            tipo: TipoReporte.print,
            titulo: 'Título qualquer',
            relato: '   ',
            categoria: CategoriaAmeaca.outroGolpe,
          ),
        ),
        MotivoRecusaReporte.relatoVazio,
      );
    });

    test('relato longo demais é recusado', () {
      expect(
        recusa(
          prepararReporte(
            tipo: TipoReporte.relato,
            titulo: 'Título qualquer',
            relato: 'a' * 1001,
            categoria: CategoriaAmeaca.outroGolpe,
          ),
        ),
        MotivoRecusaReporte.relatoLongo,
      );
    });
  });

  group('palavras de busca (RF15)', () {
    test('minúsculas, sem acento, sem marcadores e sem repetição', () {
      expect(
        palavrasDeBusca(['Falso PARENTE pede Pix [CPF] já', 'Falso contato']),
        ['falso', 'parente', 'pede', 'pix', 'contato'],
      );
    });

    test('no máximo 20 palavras', () {
      final muitas = List.generate(30, (i) => 'palavra$i').join(' ');
      expect(palavrasDeBusca([muitas]), hasLength(maximoPalavras));
    });

    test('o reporte leva as palavras do título e da categoria', () {
      final r = pronto(
        prepararReporte(
          tipo: TipoReporte.relato,
          titulo: 'Prêmio de sorteio',
          relato: 'Disseram que ganhei.',
          categoria: CategoriaAmeaca.ofertaOuPremioFalso,
        ),
      );
      expect(r.palavras, containsAll(['premio', 'sorteio', 'oferta', 'falso']));
    });
  });
}
