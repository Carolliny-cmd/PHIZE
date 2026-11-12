import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:phize/features/analise/domain/analise_risco.dart';
import 'package:phize/features/analise/domain/categoria_ameaca.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/resultado_analise_print.dart';
import 'package:phize/features/analise/domain/rotulos_risco.dart';
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
}
