import 'package:flutter/material.dart';

class AnalisadorLinksScreen extends StatefulWidget {
  const AnalisadorLinksScreen({super.key});

  @override
  State<AnalisadorLinksScreen> createState() => _AnalisadorLinksScreenState();
}

class _AnalisadorLinksScreenState extends State<AnalisadorLinksScreen> {
  final _linkController = TextEditingController();
  bool _analisando = false;
  String? _resultado;
  double _score = 0;
  Color _corResultado = Colors.green;
  String _statusTexto = '';

  void _analisarLink() async {
    if (_linkController.text.isEmpty) return;

    setState(() {
      _analisando = true;
      _resultado = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    final link = _linkController.text.toLowerCase();
    double score = 0.1;
    String status = 'SEGURO';
    Color cor = const Color(0xFF00B894);

    if (link.contains('bit.ly') || link.contains('tinyurl') || link.contains('encurtador')) {
      score = 0.6;
      status = 'SUSPEITO';
      cor = const Color(0xFFFFA502);
    }

    if (link.contains('pix') || link.contains('urgente') || link.contains('gratis') ||
        link.contains('ganhe') || link.contains('click') || link.contains('senha')) {
      score = 0.88;
      status = 'PERIGOSO';
      cor = const Color(0xFFFF4757);
    }

    setState(() {
      _analisando = false;
      _resultado = status;
      _score = score;
      _corResultado = cor;
      _statusTexto = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
        title: const Text(
          'Analisar Link',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF00D4FF), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cole o link suspeito abaixo para verificar se é seguro.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _linkController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cole o link aqui',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.link, color: Color(0xFF00D4FF)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _analisando ? null : _analisarLink,
                icon: _analisando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A2E)),
                      )
                    : const Icon(Icons.search),
                label: Text(_analisando ? 'Analisando...' : 'Analisar Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF1A1A2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_resultado != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _corResultado.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Icon(
                      _resultado == 'SEGURO' ? Icons.check_circle : _resultado == 'SUSPEITO' ? Icons.warning : Icons.dangerous,
                      color: _corResultado,
                      size: 60,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusTexto,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _corResultado),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _score,
                        minHeight: 12,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(_corResultado),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_score * 100).toInt()}% de periculosidade',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _resultado == 'SEGURO'
                          ? 'Nenhum indicador de fraude encontrado neste link.'
                          : _resultado == 'SUSPEITO'
                              ? 'Este link usa encurtador. Verifique antes de clicar.'
                              : 'Este link contém padrões típicos de golpe. Não clique!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
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