import 'package:flutter/material.dart';

/// Resultado da análise de um link.
class ResultadoAnalise {
  final int score;
  final List<String> motivos;

  const ResultadoAnalise({required this.score, required this.motivos});

  /// baixo | medio | alto
  String get nivel {
    if (score >= 5) return 'alto';
    if (score >= 2) return 'medio';
    return 'baixo';
  }

  String get rotulo {
    switch (nivel) {
      case 'alto':
        return 'ALTO RISCO';
      case 'medio':
        return 'RISCO MODERADO';
      default:
        return 'BAIXO RISCO';
    }
  }

  Color get cor {
    switch (nivel) {
      case 'alto':
        return const Color(0xFFFF4757);
      case 'medio':
        return const Color(0xFFFFA502);
      default:
        return const Color(0xFF00B894);
    }
  }

  IconData get icone {
    switch (nivel) {
      case 'alto':
        return Icons.dangerous_rounded;
      case 'medio':
        return Icons.warning_amber_rounded;
      default:
        return Icons.verified_rounded;
    }
  }
}

/// Analisa uma URL usando heurísticas comuns de phishing/golpe.
/// Isso NÃO é uma verificação definitiva — é um alerta baseado em padrões.
ResultadoAnalise analisarLink(String entrada) {
  final motivos = <String>[];
  int score = 0;

  var texto = entrada.trim();
  if (texto.isEmpty) {
    return const ResultadoAnalise(score: 0, motivos: []);
  }

  // Garante um esquema para conseguir parsear com Uri
  final temEsquema = texto.startsWith('http://') || texto.startsWith('https://');
  final urlParaAnalise = temEsquema ? texto : 'https://$texto';

  final uri = Uri.tryParse(urlParaAnalise);
  if (uri == null || uri.host.isEmpty) {
    return const ResultadoAnalise(
      score: 5,
      motivos: ['O texto informado não parece ser um link válido.'],
    );
  }

  final host = uri.host.toLowerCase();

  // 1. Não usa HTTPS
  if (temEsquema && texto.startsWith('http://')) {
    score += 2;
    motivos.add('Não usa conexão segura (HTTP em vez de HTTPS).');
  }

  // 2. Host é um endereço IP puro
  final regexIp = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
  if (regexIp.hasMatch(host)) {
    score += 3;
    motivos.add('Usa um endereço IP numérico em vez de um domínio — comum em golpes.');
  }

  // 3. Contém '@' na URL (técnica de mascarar destino real)
  if (texto.contains('@')) {
    score += 3;
    motivos.add("Contém o caractere '@', usado para esconder o destino real do link.");
  }

  // 4. TLDs frequentemente associados a abuso/golpes
  const tldsSuspeitas = [
    '.tk', '.ml', '.ga', '.cf', '.gq', '.xyz', '.top', '.click',
    '.work', '.support', '.zip', '.country', '.gdn',
  ];
  for (final tld in tldsSuspeitas) {
    if (host.endsWith(tld)) {
      score += 2;
      motivos.add("Usa a extensão '$tld', frequentemente associada a sites falsos.");
      break;
    }
  }

  // 5. Encurtadores de link (escondem o destino real)
  const encurtadores = [
    'bit.ly', 'tinyurl.com', 'is.gd', 'cutt.ly', 't.co', 'rebrand.ly',
    'shorturl.at', 'rb.gy', 'ow.ly',
  ];
  if (encurtadores.any((e) => host == e || host.endsWith('.$e'))) {
    score += 2;
    motivos.add('É um link encurtado — o destino real fica escondido até você clicar.');
  }

  // 6. Imitação de marcas conhecidas fora do domínio oficial
  const marcas = {
    'paypal': 'paypal.com',
    'itau': 'itau.com.br',
    'bradesco': 'bradesco.com.br',
    'caixa': 'caixa.gov.br',
    'nubank': 'nubank.com.br',
    'mercadolivre': 'mercadolivre.com.br',
    'mercadopago': 'mercadopago.com',
    'whatsapp': 'whatsapp.com',
    'instagram': 'instagram.com',
    'facebook': 'facebook.com',
    'google': 'google.com',
    'netflix': 'netflix.com',
    'amazon': 'amazon.com',
    'gov.br': 'gov.br',
    'serasa': 'serasa.com.br',
  };
  for (final marca in marcas.keys) {
    if (host.contains(marca) && !host.endsWith(marcas[marca]!)) {
      score += 4;
      motivos.add(
        "O link menciona '$marca' mas não é o domínio oficial ($host) — sinal forte de phishing.",
      );
      break;
    }
  }

  // 7. Palavras de urgência/engano no caminho ou domínio
  const palavrasSuspeitas = [
    'verificar-conta', 'verify-account', 'confirmar-dados', 'atualize-agora',
    'suporte-urgente', 'premio', 'sorteio', 'ganhou', 'recuperar-senha',
    'confirmar-identidade', 'bloqueado', 'suspenso',
  ];
  final urlCompleta = texto.toLowerCase();
  for (final palavra in palavrasSuspeitas) {
    if (urlCompleta.contains(palavra)) {
      score += 1;
      motivos.add("Contém o termo '$palavra', comum em golpes de urgência falsa.");
      break;
    }
  }

  // 8. Excesso de hífens no domínio (comum em domínios falsos)
  final hifens = '-'.allMatches(host).length;
  if (hifens >= 3) {
    score += 1;
    motivos.add('O domínio tem muitos hífens, um padrão comum em sites falsos.');
  }

  // 9. Excesso de subdomínios
  final partes = host.split('.');
  if (partes.length >= 5) {
    score += 1;
    motivos.add('O endereço tem muitos subdomínios, o que pode indicar tentativa de disfarce.');
  }

  // 10. URL muito longa
  if (texto.length > 90) {
    score += 1;
    motivos.add('O link é incomumente longo, técnica usada para dificultar a leitura do destino.');
  }

  // 11. Punycode (imita letras de domínios legítimos com caracteres unicode)
  if (host.contains('xn--')) {
    score += 3;
    motivos.add('Usa codificação punycode, técnica para imitar visualmente domínios legítimos.');
  }

  if (motivos.isEmpty) {
    motivos.add('Nenhum padrão suspeito comum foi identificado neste link.');
  }

  return ResultadoAnalise(score: score, motivos: motivos);
}

class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final _controller = TextEditingController();
  ResultadoAnalise? _resultado;

  void _verificar() {
    final texto = _controller.text;
    setState(() {
      _resultado = analisarLink(texto);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Analisar Link',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole o link que deseja verificar',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _verificar(),
              decoration: InputDecoration(
                hintText: 'https://exemplo.com',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verificar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verificar',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (resultado != null) ...[
              const SizedBox(height: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: resultado.cor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(resultado.icone, color: resultado.cor, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          resultado.rotulo,
                          style: TextStyle(
                            color: resultado.cor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Por quê:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...resultado.motivos.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: resultado.cor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                m,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta análise é baseada em padrões comuns e não substitui seu bom senso. Em caso de dúvida, não clique no link.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}