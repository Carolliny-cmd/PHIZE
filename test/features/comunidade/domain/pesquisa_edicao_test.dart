import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/pesquisa_reportes.dart';
import 'package:phize/features/comunidade/domain/preparacao_reporte.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

/// Conteúdo fictício em todos os casos.
void main() {
  group('pesquisa (RF15)', () {
    test('link vira a mesma hash do reporte, com qualquer variação', () {
      final esperada = hashDoLink('entrega-taxa.example');
      for (final entrada in [
        'entrega-taxa.example',
        'https://www.entrega-taxa.example/pagar?id=9',
        '  http://ENTREGA-TAXA.example/  ',
      ]) {
        final consulta = interpretarPesquisa(entrada);
        expect(consulta, isA<ConsultaPorLink>(), reason: entrada);
        expect((consulta! as ConsultaPorLink).hash, esperada);
      }
    });

    test('texto vira palavras de busca, sem acento', () {
      final consulta = interpretarPesquisa('Falso Parente pedindo PIX');
      expect(consulta, isA<ConsultaPorPalavras>());
      expect((consulta! as ConsultaPorPalavras).palavras, [
        'falso',
        'parente',
        'pedindo',
        'pix',
      ]);
      expect(
        (interpretarPesquisa('cobrança')! as ConsultaPorPalavras).palavras,
        ['cobranca'],
      );
    });

    test('no máximo 10 palavras (limite do Firestore)', () {
      final consulta = interpretarPesquisa(
        'um1 dois tres quatro cinco seis sete oito nove dez onze doze',
      );
      expect(
        (consulta! as ConsultaPorPalavras).palavras,
        hasLength(maximoPalavrasPesquisa),
      );
    });

    test('nada para pesquisar volta null', () {
      expect(interpretarPesquisa(''), isNull);
      expect(interpretarPesquisa('   '), isNull);
      expect(interpretarPesquisa('a de'), isNull);
    });
  });

  group('edição (RF16)', () {
    test('mascara de novo e troca links', () {
      final edicao = prepararEdicao(
        tipo: TipoReporte.relato,
        titulo: 'Pediu CPF 123.456.789-09',
        relato: 'Mandou pagar em https://golpe.example/x',
        categoria: CategoriaAmeaca.rouboDeDados,
      ) as EdicaoPronta;
      expect(edicao.titulo, 'Pediu CPF [CPF]');
      expect(edicao.relato, 'Mandou pagar em [LINK]');
      expect(edicao.palavras, containsAll(['pediu', 'cpf', 'roubo', 'dados']));
    });

    test('mesmos limites do reporte novo', () {
      expect(
        prepararEdicao(
          tipo: TipoReporte.relato,
          titulo: 'ab',
          relato: 'texto',
          categoria: CategoriaAmeaca.outroGolpe,
        ),
        MotivoRecusaReporte.tituloCurto,
      );
      expect(
        prepararEdicao(
          tipo: TipoReporte.relato,
          titulo: 'Título bom',
          relato: '   ',
          categoria: CategoriaAmeaca.outroGolpe,
        ),
        MotivoRecusaReporte.relatoVazio,
      );
      expect(
        prepararEdicao(
          tipo: TipoReporte.relato,
          titulo: 'Título bom',
          relato: 'x' * 1001,
          categoria: CategoriaAmeaca.outroGolpe,
        ),
        MotivoRecusaReporte.relatoLongo,
      );
    });

    test('reporte de link pode ficar sem relato', () {
      expect(
        prepararEdicao(
          tipo: TipoReporte.link,
          titulo: 'Entrega com taxa',
          relato: '',
          categoria: CategoriaAmeaca.cobrancaOuBoletoFalso,
        ),
        isA<EdicaoPronta>(),
      );
    });
  });
}
