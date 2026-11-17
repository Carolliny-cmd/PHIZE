import 'motivo_denuncia.dart';
import 'reporte_comunidade.dart';

/// Resultado da pesquisa por link (RF15).
class ResultadoPesquisaLink {
  const ResultadoPesquisaLink({this.reporte, this.validadoPelaEquipe = false});

  /// O reporte desse link, se estiver visível (pendente ou aprovado).
  final ReporteComunidade? reporte;

  /// A hash está entre as ameaças validadas pela equipe (`ameacas`), mesmo
  /// que o reporte de origem já tenha sido excluído (RF12).
  final bool validadoPelaEquipe;
}

/// Leitura do feed e curtidas da comunidade (RF06, RF08). A implementação
/// real usa o Firestore (`docs/comunidade-dados.md`); os testes de tela usam
/// um dublê.
abstract class FeedRepository {
  /// Quantos reportes o feed carrega de cada vez.
  static const int limite = 50;

  /// Reportes visíveis (pendentes e aprovados; ocultos nunca), na ordem
  /// pedida. Lança exceção em falha de comunicação.
  Future<List<ReporteComunidade>> listar(OrdemFeed ordem);

  /// Se a conta atual já curtiu o reporte.
  Future<bool> jaCurtiu(String reporteId);

  /// Registra a curtida da conta atual: +1 no reporte junto com a marca da
  /// conta, uma vez só (RF06). Lança exceção se não for possível, inclusive
  /// se a conta já tinha curtido.
  Future<void> curtir(String reporteId);

  /// Se a conta atual já denunciou o reporte.
  Future<bool> jaDenunciou(String reporteId);

  /// Registra a denúncia da conta atual com o motivo: +1 no reporte junto
  /// com a marca da conta, uma vez só (RF11). Com 3 denúncias, uma Function
  /// oculta o reporte até a revisão da equipe. Lança exceção se não for
  /// possível, inclusive se a conta já tinha denunciado.
  Future<void> denunciar(String reporteId, MotivoDenuncia motivo);

  /// Pesquisa pela hash do link (RF15). O endereço nunca sai do aparelho.
  Future<ResultadoPesquisaLink> pesquisarLink(String hash);

  /// Reportes visíveis que tenham alguma das [palavras] no título ou na
  /// categoria (RF15), os que casam mais palavras primeiro.
  Future<List<ReporteComunidade>> pesquisarPalavras(List<String> palavras);
}
