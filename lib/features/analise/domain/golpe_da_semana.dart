import '../../../shared/domain/categoria_ameaca.dart';

/// Modalidade de golpe mostrada no cartão "Golpe da semana" (RF17). O texto
/// vem igual ao da ficha revisada pela curadoria humana (RNF05), sem
/// reescrita por modelo de linguagem.
class FichaEducativa {
  const FichaEducativa({
    required this.id,
    required this.modalidade,
    required this.categoria,
    required this.canais,
    required this.frasesComuns,
    required this.oQuePedem,
    required this.oQueFazer,
    required this.fontes,
  });

  final String id;
  final String modalidade;
  final CategoriaAmeaca categoria;
  final List<String> canais;

  /// Os gatilhos linguísticos da ficha: frases típicas do golpista.
  final List<String> frasesComuns;

  /// O padrão de solicitação financeira da ficha.
  final String oQuePedem;

  /// A orientação preventiva da ficha.
  final String oQueFazer;

  /// Publicador e título de cada fonte pública da ficha.
  final List<({String publicador, String titulo})> fontes;

  /// Lê um item do arquivo gerado por `tool/gerar_golpe_da_semana.dart`.
  /// `null` se faltar algum campo ou a categoria for desconhecida.
  static FichaEducativa? doJson(Object? json) {
    if (json is! Map) return null;
    final categoria = CategoriaAmeaca.doCodigo(json['categoria']);
    final id = json['id'];
    final modalidade = json['modalidade'];
    final canais = json['canais'];
    final frases = json['frasesComuns'];
    final oQuePedem = json['oQuePedem'];
    final oQueFazer = json['oQueFazer'];
    final fontes = json['fontes'];
    if (categoria == null ||
        id is! String ||
        modalidade is! String ||
        canais is! List ||
        frases is! List ||
        oQuePedem is! String ||
        oQueFazer is! String ||
        fontes is! List) {
      return null;
    }
    return FichaEducativa(
      id: id,
      modalidade: modalidade,
      categoria: categoria,
      canais: canais.whereType<String>().toList(),
      frasesComuns: frases.whereType<String>().toList(),
      oQuePedem: oQuePedem,
      oQueFazer: oQueFazer,
      fontes: [
        for (final fonte in fontes)
          if (fonte case {
            'publicador': final String publicador,
            'titulo': final String titulo,
          })
            (publicador: publicador, titulo: titulo),
      ],
    );
  }
}

/// Início da contagem das semanas: segunda-feira, 5 de janeiro de 1970.
final DateTime _primeiraSegunda = DateTime.utc(1970, 1, 5);

/// Número da semana no horário de Brasília (UTC-3, sem horário de verão
/// desde 2019), com a semana começando na segunda-feira à meia-noite. Não
/// depende do fuso do aparelho: todos veem a mesma semana.
int semanaDe(DateTime instante) {
  final brasilia = instante.toUtc().subtract(const Duration(hours: 3));
  final dias = brasilia.difference(_primeiraSegunda).inDays;
  return dias ~/ 7;
}

/// O golpe da semana (RF17): rodízio determinístico entre as fichas, em
/// ordem de identificador, de modo que todos os usuários vejam a mesma
/// modalidade na mesma semana. `null` se não houver fichas.
FichaEducativa? golpeDaSemana(List<FichaEducativa> fichas, DateTime agora) {
  if (fichas.isEmpty) return null;
  final ordenadas = [...fichas]..sort((a, b) => a.id.compareTo(b.id));
  return ordenadas[semanaDe(agora) % ordenadas.length];
}

/// Fonte das fichas do cartão. A implementação real lê o arquivo embutido no
/// app: a exibição não faz chamada de rede nem envia dado algum (RF17).
abstract class GolpeDaSemanaRepository {
  Future<List<FichaEducativa>> fichas();
}
