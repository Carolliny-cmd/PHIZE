import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/data/golpe_da_semana_asset.dart';
import 'package:phize/features/analise/domain/golpe_da_semana.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';

import '../../../../tool/gerar_golpe_da_semana.dart' as gerador;

FichaEducativa _ficha(String id) => FichaEducativa(
  id: id,
  modalidade: 'Modalidade $id',
  categoria: CategoriaAmeaca.outroGolpe,
  canais: const ['WhatsApp'],
  frasesComuns: const ['frase'],
  oQuePedem: 'Pix',
  oQueFazer: 'Confirme pelo canal oficial.',
  fontes: const [],
);

void main() {
  group('semana (RF17)', () {
    test('a semana vira na segunda-feira à meia-noite de Brasília', () {
      // Domingo, 15/11/2026, 23:59 em Brasília = segunda, 02:59 UTC.
      final domingo = DateTime.utc(2026, 11, 16, 2, 59);
      // Segunda, 16/11/2026, 00:00 em Brasília = 03:00 UTC.
      final segunda = DateTime.utc(2026, 11, 16, 3);
      expect(semanaDe(segunda), semanaDe(domingo) + 1);
      // Mesma semana até o domingo seguinte.
      expect(semanaDe(DateTime.utc(2026, 11, 23, 2, 59)), semanaDe(segunda));
    });

    test('não depende do fuso do aparelho', () {
      final instante = DateTime.utc(2026, 11, 18, 12);
      expect(semanaDe(instante.toLocal()), semanaDe(instante));
    });
  });

  group('rodízio (RF17)', () {
    final fichas = [_ficha('c'), _ficha('a'), _ficha('b')];

    test('a mesma semana dá sempre a mesma ficha, em qualquer ordem', () {
      final agora = DateTime.utc(2026, 11, 18, 12);
      final primeira = golpeDaSemana(fichas, agora)!;
      expect(golpeDaSemana(fichas.reversed.toList(), agora)!.id, primeira.id);
      expect(
        golpeDaSemana(fichas, agora.add(const Duration(days: 2)))!.id,
        primeira.id,
      );
    });

    test('passa por todas as fichas, uma por semana', () {
      final inicio = DateTime.utc(2026, 11, 16, 12);
      final vistas = {
        for (var i = 0; i < 3; i++)
          golpeDaSemana(fichas, inicio.add(Duration(days: 7 * i)))!.id,
      };
      expect(vistas, {'a', 'b', 'c'});
    });

    test('sem fichas, sem cartão', () {
      expect(golpeDaSemana(const [], DateTime.now()), isNull);
    });
  });

  group('arquivo embutido', () {
    test('está igual às fichas revisadas da base (rode o gerador)', () {
      final atual = File(caminhoGolpeDaSemana).readAsStringSync();
      final esperado = gerador.gerarTexto(gerador.lerFichas());
      expect(
        atual.replaceAll('\r\n', '\n'),
        esperado,
        reason:
            'Arquivo desatualizado: rode dart run '
            'tool/gerar_golpe_da_semana.dart',
      );
    });

    test('copia o texto das fichas sem mudança', () {
      final fichas = {
        for (final ficha in gerador.lerFichas()) ficha['id']: ficha,
      };
      final conteudo =
          jsonDecode(File(caminhoGolpeDaSemana).readAsStringSync()) as Map;
      for (final item in conteudo['fichas'] as List) {
        final original = fichas[item['id']]!;
        expect(item['modalidade'], original['modalidade']);
        expect(item['frasesComuns'], original['gatilhosLinguisticos']);
        expect(item['oQuePedem'], original['padraoSolicitacaoFinanceira']);
        expect(item['oQueFazer'], original['orientacaoPreventiva']);
      }
    });

    test('não leva quem revisou, links nem situações legítimas', () {
      final texto = File(caminhoGolpeDaSemana).readAsStringSync();
      // Chaves com aspas: "Procuradoria", nome de uma fonte, contém a
      // palavra "curadoria".
      for (final proibido in [
        '"revisadoPor"',
        '"curadoria"',
        '"situacoesLegitimas"',
        'http',
      ]) {
        expect(texto, isNot(contains(proibido)), reason: proibido);
      }
    });

    test('só entra ficha com curadoria preenchida (RNF05)', () {
      final conteudo = gerador.conteudoDasFichas([
        {
          'id': 'sem-revisao',
          'modalidade': 'x',
          'categoria': 'outro_golpe',
          'canais': <String>[],
          'gatilhosLinguisticos': <String>[],
          'padraoSolicitacaoFinanceira': 'x',
          'orientacaoPreventiva': 'x',
          'fontes': <Object>[],
          'curadoria': {'revisadoPor': '', 'revisadoEm': ''},
        },
      ]);
      expect(conteudo['fichas'], isEmpty);
    });

    test('todas as fichas do arquivo são lidas pelo app', () {
      final conteudo =
          jsonDecode(File(caminhoGolpeDaSemana).readAsStringSync()) as Map;
      final lista = conteudo['fichas'] as List;
      expect(lista, isNotEmpty);
      for (final item in lista) {
        expect(FichaEducativa.doJson(item), isNotNull, reason: '${item['id']}');
      }
    });
  });
}
