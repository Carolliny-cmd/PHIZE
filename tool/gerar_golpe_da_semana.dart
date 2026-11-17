// Gera o conteúdo do cartão "Golpe da semana" (RF17) a partir das fichas
// revisadas da base de conhecimento (functions/base-conhecimento/fichas).
// Copia os textos como estão, sem reescrita, e deixa de fora o que o cartão
// não mostra (situações legítimas, links das fontes e quem revisou).
//
//   dart run tool/gerar_golpe_da_semana.dart
//
// Rode depois de incluir ou alterar uma ficha. O teste
// test/features/analise/domain/golpe_da_semana_test.dart falha se o arquivo
// estiver desatualizado.
import 'dart:convert';
import 'dart:io';

const String pastaFichas = 'functions/base-conhecimento/fichas';
const String arquivoSaida = 'assets/conteudo/golpe_da_semana.json';

/// Só entra ficha com curadoria preenchida (RNF05).
bool revisada(Map<String, dynamic> ficha) {
  final curadoria = ficha['curadoria'];
  return curadoria is Map &&
      '${curadoria['revisadoPor'] ?? ''}'.trim().isNotEmpty &&
      '${curadoria['revisadoEm'] ?? ''}'.trim().isNotEmpty;
}

/// Conteúdo do arquivo, em ordem de identificador. Função pura, usada
/// também pelo teste de sincronia.
Map<String, Object> conteudoDasFichas(List<Map<String, dynamic>> fichas) {
  final revisadas = fichas.where(revisada).toList()
    ..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
  return {
    'origem':
        'Gerado por tool/gerar_golpe_da_semana.dart a partir de '
        '$pastaFichas. Não editar à mão.',
    'fichas': [
      for (final ficha in revisadas)
        {
          'id': ficha['id'],
          'modalidade': ficha['modalidade'],
          'categoria': ficha['categoria'],
          'canais': ficha['canais'],
          'frasesComuns': ficha['gatilhosLinguisticos'],
          'oQuePedem': ficha['padraoSolicitacaoFinanceira'],
          'oQueFazer': ficha['orientacaoPreventiva'],
          'fontes': [
            for (final fonte in ficha['fontes'] as List)
              {'publicador': fonte['publicador'], 'titulo': fonte['titulo']},
          ],
        },
    ],
  };
}

List<Map<String, dynamic>> lerFichas([String pasta = pastaFichas]) => [
  for (final arquivo in Directory(pasta).listSync().whereType<File>())
    if (arquivo.path.endsWith('.json'))
      jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>,
];

String gerarTexto(List<Map<String, dynamic>> fichas) =>
    '${const JsonEncoder.withIndent('  ').convert(conteudoDasFichas(fichas))}\n';

void main() {
  final fichas = lerFichas();
  final saida = File(arquivoSaida)..createSync(recursive: true);
  saida.writeAsStringSync(gerarTexto(fichas));
  final total = (conteudoDasFichas(fichas)['fichas'] as List).length;
  stdout.writeln('$total fichas revisadas gravadas em $arquivoSaida');
}
