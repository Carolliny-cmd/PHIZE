import 'dart:convert';

import '../../analise/domain/analise_risco.dart';
import '../../analise/domain/faixa_risco.dart';
import '../../analise/domain/resultado_analise_print.dart';
import '../../comunidade/domain/meus_reportes_repository.dart';
import '../../comunidade/domain/reporte_comunidade.dart';
import 'conta_repository.dart';

const String nomeArquivoExportacao = 'phize-meus-dados.json';

/// Compila os dados da conta em arquivo legível (RF12; UC12, passo 3). O
/// histórico só tem o resultado das análises, então o arquivo também não
/// traz nenhum conteúdo analisado (RNF01). Da comunidade, vão os reportes
/// publicados pela conta e as curtidas, denúncias e "também recebi" que ela
/// deu (RF12, RF16).
String montarExportacao({
  required PerfilConta perfil,
  required List<AnaliseRisco> analises,
  required DateTime geradoEm,
  ParticipacaoComunidade comunidade = ParticipacaoComunidade.vazia,
}) {
  final dados = {
    'geradoEm': geradoEm.toIso8601String(),
    'perfil': {
      'identificador': perfil.uid,
      'email': perfil.email,
      'nomeExibicao': perfil.nomeExibicao,
      'contaCriadaEm': perfil.criadaEm?.toIso8601String(),
    },
    'analises': [
      for (final analise in analises)
        {
          'data': analise.data.toIso8601String(),
          'tipoEntrada': switch (analise.tipoEntrada) {
            TipoEntrada.link => 'Link',
            TipoEntrada.imagem => 'Print',
          },
          'score': analise.score,
          'veredito': analise.faixa.rotulo,
          'categoria': analise.categoria?.nome,
          'explicacao': analise.explicacao,
        },
    ],
    'comunidade': {
      'reportes': [
        for (final meu in comunidade.reportes)
          {
            'identificador': meu.id,
            'publicadoEm': meu.publicadoEm.toIso8601String(),
            ...switch (meu.reporte) {
              null => {'situacao': 'Removido pela moderação'},
              final reporte => {
                'situacao': _situacao(reporte.status),
                'tipo': reporte.tipo.nome,
                'titulo': reporte.titulo,
                'relato': reporte.relato,
                'categoria': reporte.categoria.nome,
                'curtidas': reporte.curtidas,
                'pessoasQueRelataram': reporte.incidencias,
              },
            },
          },
      ],
      'curtidas': [
        for (final MapEntry(key: id, value: data)
            in comunidade.curtidas.entries)
          {'reporte': id, 'data': data.toIso8601String()},
      ],
      'denuncias': [
        for (final MapEntry(key: id, value: motivo)
            in comunidade.denuncias.entries)
          {'reporte': id, 'motivo': motivo?.nome},
      ],
      'tambemRecebi': [
        for (final MapEntry(key: id, value: data)
            in comunidade.incidencias.entries)
          {'reporte': id, 'data': data.toIso8601String()},
      ],
    },
  };
  return const JsonEncoder.withIndent('  ').convert(dados);
}

String _situacao(StatusReporte status) => switch (status) {
  StatusReporte.pendente => 'Aguardando revisão',
  StatusReporte.aprovado => 'Aprovado pela equipe',
  StatusReporte.oculto => 'Em revisão pela equipe',
};
