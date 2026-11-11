import 'package:phize/features/analise/domain/calculadora_score.dart';
import 'package:phize/features/analise/domain/faixa_risco.dart';
import 'package:phize/features/analise/domain/resposta_modelo.dart';
import 'package:phize/features/analise/domain/sinais_identificados.dart';
import 'package:phize/features/analise/domain/sinal_texto_print.dart';

/// Etapa 5 do plano do RAG (docs/calibracao-recuperacao.md): converte os
/// sinais gravados por `npm run avaliar-analise` em faixa de risco, usando o
/// próprio motor do app ([CalculadoraScore]). Assim os pesos continuam só em
/// `ScoreConfig`, sem cópia no script da Function.
///
/// A faixa "sem a base" é calculada sem a regra de verificação incompleta:
/// mede o que o modelo encontra sozinho. No app, a base indisponível impede
/// a faixa verde (docs/score-calibracao.md).
///
/// Fica em `test/` por ser ferramenta de avaliação, não código do app.

/// Uma rodada do relatório, como `avaliacaoAnalise.ts` grava.
class RodadaRelatorio {
  const RodadaRelatorio({
    required this.mensagem,
    required this.grupo,
    required this.modo,
    required this.sinais,
    required this.padrao,
    required this.esperado,
  });

  factory RodadaRelatorio.deJson(Map<String, Object?> json) => RodadaRelatorio(
        mensagem: json['mensagem']! as String,
        grupo: json['grupo']! as String,
        modo: json['modo']! as String,
        sinais: (json['sinais']! as List).cast<String>(),
        padrao: json['padrao'] as String?,
        esperado: json['esperado'] as String?,
      );

  final String mensagem;

  /// `golpe` ou `legitima`.
  final String grupo;

  /// `com_base` ou `sem_base`.
  final String modo;
  final List<String> sinais;
  final String? padrao;
  final String? esperado;
}

/// Tipo da mensagem para o resumo.
enum TipoMensagem { golpeDaBase, golpeForaDaBase, legitima }

/// Faixa de uma mensagem em cada modo.
class FaixasMensagem {
  const FaixasMensagem({
    required this.mensagem,
    required this.tipo,
    required this.semBase,
    required this.comBase,
    required this.padraoComBase,
  });

  final String mensagem;
  final TipoMensagem tipo;
  final FaixaRisco? semBase;
  final FaixaRisco? comBase;

  /// Padrão apontado com a base na maioria das rodadas, se houver.
  final String? padraoComBase;

  bool get comparavel => semBase != null && comBase != null;
  bool get subiu => comparavel && comBase!.index > semBase!.index;
  bool get desceu => comparavel && comBase!.index < semBase!.index;
}

class ResumoTipo {
  ResumoTipo();

  int total = 0;
  final Map<FaixaRisco, int> semBase = {for (final f in FaixaRisco.values) f: 0};
  final Map<FaixaRisco, int> comBase = {for (final f in FaixaRisco.values) f: 0};
  final List<String> subiram = [];
  final List<String> desceram = [];

  Map<String, Object> paraJson() => {
        'total': total,
        'semBase': {for (final e in semBase.entries) e.key.name: e.value},
        'comBase': {for (final e in comBase.entries) e.key.name: e.value},
        'subiram': subiram,
        'desceram': desceram,
      };
}

/// Faixa de uma rodada, pelo motor do app. Sinal desconhecido é ignorado
/// (a Function já recusa resposta com sinal fora do contrato).
FaixaRisco faixaDosSinais(List<String> codigos) {
  final sinais = <SinalTextoPrint>{
    for (final c in codigos) ?RespostaModelo.codigosSinais[c],
  };
  return CalculadoraScore.calcular(SinaisIdentificados(textoPrint: sinais))
      .faixa;
}

/// Faixa mais frequente entre as repetições; empate fica com a mais alta,
/// a favor da cautela.
FaixaRisco? _faixaDaMaioria(List<RodadaRelatorio> rodadas) {
  if (rodadas.isEmpty) return null;
  final contagem = <FaixaRisco, int>{};
  for (final r in rodadas) {
    final f = faixaDosSinais(r.sinais);
    contagem[f] = (contagem[f] ?? 0) + 1;
  }
  return contagem.entries
      .reduce((a, b) =>
          b.value > a.value || (b.value == a.value && b.key.index > a.key.index)
              ? b
              : a)
      .key;
}

String? _padraoDaMaioria(List<RodadaRelatorio> rodadas) {
  final contagem = <String, int>{};
  for (final r in rodadas) {
    if (r.padrao case final p?) contagem[p] = (contagem[p] ?? 0) + 1;
  }
  if (contagem.isEmpty) return null;
  final maior = contagem.values.reduce((a, b) => a > b ? a : b);
  if (maior * 2 < rodadas.length) return null;
  return (contagem.entries.where((e) => e.value == maior).map((e) => e.key).toList()
        ..sort())
      .first;
}

TipoMensagem _tipo(RodadaRelatorio r) => r.grupo == 'legitima'
    ? TipoMensagem.legitima
    : r.esperado == null
        ? TipoMensagem.golpeForaDaBase
        : TipoMensagem.golpeDaBase;

/// Faixas por mensagem, na ordem em que aparecem no relatório.
List<FaixasMensagem> faixasPorMensagem(List<RodadaRelatorio> rodadas) {
  final porMensagem = <String, List<RodadaRelatorio>>{};
  for (final r in rodadas) {
    porMensagem.putIfAbsent(r.mensagem, () => []).add(r);
  }
  return [
    for (final MapEntry(key: mensagem, value: grupo) in porMensagem.entries)
      FaixasMensagem(
        mensagem: mensagem,
        tipo: _tipo(grupo.first),
        semBase: _faixaDaMaioria(grupo.where((r) => r.modo == 'sem_base').toList()),
        comBase: _faixaDaMaioria(grupo.where((r) => r.modo == 'com_base').toList()),
        padraoComBase:
            _padraoDaMaioria(grupo.where((r) => r.modo == 'com_base').toList()),
      ),
  ];
}

/// Contagem por faixa em cada modo e mensagens que mudaram de faixa, por
/// tipo. Mensagem sem rodada válida em algum modo fica fora da contagem.
Map<TipoMensagem, ResumoTipo> resumirFaixas(List<FaixasMensagem> faixas) {
  final resumo = {for (final t in TipoMensagem.values) t: ResumoTipo()};
  for (final f in faixas) {
    if (!f.comparavel) continue;
    final r = resumo[f.tipo]!;
    r.total++;
    r.semBase[f.semBase!] = r.semBase[f.semBase!]! + 1;
    r.comBase[f.comBase!] = r.comBase[f.comBase!]! + 1;
    if (f.subiu) r.subiram.add(f.mensagem);
    if (f.desceu) r.desceram.add(f.mensagem);
  }
  return resumo;
}
