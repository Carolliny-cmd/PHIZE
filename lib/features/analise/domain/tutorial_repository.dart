/// Os tutoriais de primeiro uso (RF13), um por tipo de análise.
enum TipoTutorial { link, print }

/// Aumente a versão de um tutorial quando o conteúdo mudar de forma
/// relevante: quem já o viu passa a vê-lo de novo na próxima abertura.
const Map<TipoTutorial, int> versaoTutorial = {
  TipoTutorial.link: 1,
  TipoTutorial.print: 1,
};

/// Marca de tutorial visto (RF13), por usuário e só no aparelho.
abstract class TutorialRepository {
  Future<bool> visto(TipoTutorial tipo);

  Future<void> marcarVisto(TipoTutorial tipo);
}
