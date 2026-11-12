/// Organização do texto reconhecido num print de conversa (etapa 2 do plano
/// do RAG; docs/calibracao-recuperacao.md, "Texto de print").
///
/// O ML Kit devolve os blocos de texto fora da ordem de leitura e junto com
/// tudo o que aparece na tela: horários, "online", "Hoje", bateria, a barra
/// de digitação e as respostas da própria pessoa. Esta função pura, sem
/// chamada de API, recebe as linhas com a posição de cada uma e devolve:
///
/// 1. as linhas em ordem de leitura (de cima para baixo);
/// 2. sem os textos da interface do aplicativo de conversa;
/// 3. com [somenteRecebidas], só as mensagens do lado esquerdo, quando o
///    print tem cara de conversa — há ao menos uma linha alinhada à direita,
///    típica de mensagem enviada.
///
/// Não lê nem grava nada: trabalha só com o texto já em memória. Quem chama
/// continua responsável pelo descarte (RNF01, RNF07).
library;

/// Uma linha reconhecida pelo OCR, com a caixa que ocupa na imagem.
class LinhaReconhecida {
  const LinhaReconhecida({
    required this.texto,
    required this.esquerda,
    required this.topo,
    required this.direita,
    required this.base,
  });

  final String texto;
  final double esquerda;
  final double topo;
  final double direita;
  final double base;
}

/// Linha que começa até esta fração da largura é de balão recebido.
const double _limiteEsquerdaRecebida = 0.2;

/// Linha que começa depois desta fração e termina perto da borda direita é
/// de balão enviado pela própria pessoa.
const double _inicioMinimoEnviada = 0.25;
const double _fimMinimoEnviada = 0.85;

/// Textos da interface do aplicativo, não da conversa.
final List<RegExp> _ruidoInterface = [
  // Horário, sozinho ou com os tiques de leitura reconhecidos como letras.
  RegExp(
    r'^\d{1,2}[:h.]\d{2}(\s*(am|pm))?(\s*[\W_vV✓]{0,4})?$',
    caseSensitive: false,
  ),
  // Bateria e sinal.
  RegExp(r'^\d{1,3}\s?%$'),
  RegExp(
    r'^(online|digitando\.*|gravando [áa]udio\.*|hoje|ontem|mensagem|'
    r'visto por [úu]ltimo.*|mensagem apagada|esta mensagem foi apagada|'
    r'segunda-feira|ter[çc]a-feira|quarta-feira|quinta-feira|sexta-feira|'
    r's[áa]bado|domingo)$',
    caseSensitive: false,
  ),
  // Data avulsa, como as etiquetas entre mensagens.
  RegExp(r'^\d{1,2}/\d{1,2}(/\d{2,4})?$'),
];

bool _ehRuido(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return true;
  return _ruidoInterface.any((r) => r.hasMatch(t));
}

/// Texto organizado do print. [largura] é a largura da imagem, em pixels,
/// na mesma escala das caixas.
///
/// Se o filtro de [somenteRecebidas] deixaria o texto vazio, devolve as
/// linhas ordenadas sem esse filtro: na dúvida, analisar a mais.
String organizarTextoPrint(
  List<LinhaReconhecida> linhas, {
  required double largura,
  bool somenteRecebidas = true,
}) {
  final ordenadas = [...linhas]
    ..sort((a, b) {
      final porTopo = a.topo.compareTo(b.topo);
      return porTopo != 0 ? porTopo : a.esquerda.compareTo(b.esquerda);
    });
  final semRuido = ordenadas.where((l) => !_ehRuido(l.texto)).toList();

  if (somenteRecebidas && largura > 0) {
    bool enviada(LinhaReconhecida l) =>
        l.esquerda >= largura * _inicioMinimoEnviada &&
        l.direita >= largura * _fimMinimoEnviada;
    if (semRuido.any(enviada)) {
      final recebidas = semRuido
          .where((l) => l.esquerda < largura * _limiteEsquerdaRecebida)
          .toList();
      if (recebidas.isNotEmpty) return _juntar(recebidas);
    }
  }
  return _juntar(semRuido);
}

String _juntar(List<LinhaReconhecida> linhas) =>
    linhas.map((l) => l.texto.trim()).join('\n');
