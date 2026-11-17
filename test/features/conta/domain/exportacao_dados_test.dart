import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/shared/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
import 'package:phize/features/comunidade/domain/meus_reportes_repository.dart';
import 'package:phize/features/comunidade/domain/motivo_denuncia.dart';
import 'package:phize/features/comunidade/domain/novo_reporte.dart';
import 'package:phize/features/comunidade/domain/reporte_comunidade.dart';
import 'package:phize/features/conta/domain/conta_repository.dart';
import 'package:phize/features/conta/domain/exportacao_dados.dart';

void main() {
  test('reúne perfil e histórico em JSON legível', () {
    final conteudo = montarExportacao(
      perfil: PerfilConta(
        uid: 'uid-teste',
        email: 'maria@exemplo.com',
        criadaEm: DateTime(2026, 1, 2),
        nomeExibicao: 'Maria',
      ),
      analises: [
        AnaliseRisco(
          score: 85,
          faixa: FaixaRisco.alto,
          categoria: CategoriaAmeaca.falsoContato,
          explicacao: 'Explicação.',
          tipoEntrada: TipoEntrada.imagem,
          data: DateTime(2026, 11, 3),
        ),
        AnaliseRisco(
          score: 0,
          faixa: FaixaRisco.medio,
          categoria: null,
          explicacao: 'Explicação do link.',
          tipoEntrada: TipoEntrada.link,
          data: DateTime(2026, 11, 2),
        ),
      ],
      geradoEm: DateTime(2026, 11, 4),
    );

    final dados = jsonDecode(conteudo) as Map<String, dynamic>;
    expect(dados['perfil']['identificador'], 'uid-teste');
    expect(dados['perfil']['email'], 'maria@exemplo.com');
    expect(dados['perfil']['nomeExibicao'], 'Maria');
    final analises = dados['analises'] as List<dynamic>;
    expect(analises, hasLength(2));
    expect(analises[0]['veredito'], RotulosRisco.altoRisco);
    expect(analises[0]['categoria'], 'Falso contato');
    expect(analises[0]['tipoEntrada'], 'Print');
    expect(analises[1]['veredito'], RotulosRisco.medioRisco);
    expect(analises[1]['categoria'], isNull);
    expect(conteudo, contains('\n  "perfil"'));
  });

  test('conta sem análises e sem data de cadastro', () {
    final dados = jsonDecode(
      montarExportacao(
        perfil: const PerfilConta(
          uid: 'uid-teste',
          email: null,
          criadaEm: null,
        ),
        analises: const [],
        geradoEm: DateTime(2026, 11, 4),
      ),
    ) as Map<String, dynamic>;

    expect(dados['analises'], isEmpty);
    expect(dados['perfil']['contaCriadaEm'], isNull);
  });

  test('inclui a participação na comunidade (RF12, RF16)', () {
    final conteudo = montarExportacao(
      perfil: const PerfilConta(uid: 'uid-teste', email: null, criadaEm: null),
      analises: const [],
      geradoEm: DateTime(2026, 11, 17),
      comunidade: ParticipacaoComunidade(
        reportes: [
          MeuReporte(
            id: 'r1',
            publicadoEm: DateTime(2026, 11, 16),
            reporte: ReporteComunidade(
              id: 'r1',
              tipo: TipoReporte.relato,
              titulo: 'Falso parente',
              relato: 'Pediu Pix de número novo.',
              categoria: CategoriaAmeaca.falsoContato,
              curtidas: 2,
              incidencias: 1,
              status: StatusReporte.oculto,
              criadoEm: DateTime(2026, 11, 16),
            ),
          ),
          MeuReporte(id: 'r2', publicadoEm: DateTime(2026, 11, 15)),
        ],
        curtidas: {'r9': DateTime(2026, 11, 16)},
        denuncias: {'r8': MotivoDenuncia.ofensivo},
        incidencias: {'h1': DateTime(2026, 11, 16)},
      ),
    );
    final comunidade = (jsonDecode(conteudo) as Map)['comunidade'] as Map;
    final reportes = comunidade['reportes'] as List;
    expect(reportes.first, containsPair('titulo', 'Falso parente'));
    expect(reportes.first, containsPair('situacao', 'Em revisão pela equipe'));
    expect(reportes.last, containsPair('situacao', 'Removido pela moderação'));
    expect(comunidade['curtidas'], [
      {'reporte': 'r9', 'data': '2026-11-16T00:00:00.000'},
    ]);
    expect(comunidade['denuncias'], [
      {'reporte': 'r8', 'motivo': 'Conteúdo ofensivo'},
    ]);
    expect((comunidade['tambemRecebi'] as List).single['reporte'], 'h1');
  });

  test('sem participação, a seção da comunidade vem vazia', () {
    final conteudo = montarExportacao(
      perfil: const PerfilConta(uid: 'uid-teste', email: null, criadaEm: null),
      analises: const [],
      geradoEm: DateTime(2026, 11, 17),
    );
    expect((jsonDecode(conteudo) as Map)['comunidade'], {
      'reportes': [],
      'curtidas': [],
      'denuncias': [],
      'tambemRecebi': [],
    });
  });
}
