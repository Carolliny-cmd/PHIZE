import 'package:flutter/material.dart';

class AnalisadorPrintsScreen extends StatefulWidget {
  const AnalisadorPrintsScreen({super.key});

  @override
  State<AnalisadorPrintsScreen> createState() => _AnalisadorPrintsScreenState();
}

class _AnalisadorPrintsScreenState extends State<AnalisadorPrintsScreen> {
  bool _analisando = false;
  bool _imagemSelecionada = false;
  String? _resultado;
  double _score = 0;
  Color _corResultado = Colors.green;
  List<String> _frasesDetectadas = [];

  void _simularSelecaoImagem() {
    setState(() {
      _imagemSelecionada = true;
      _resultado = null;
    });
  }

  void _analisarPrint() async {
    if (!_imagemSelecionada) return;
    setState(() {
      _analisando = true;
      _resultado = null;
    });
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _analisando = false;
      _resultado = 'PERIGOSO';
      _score = 0.91;
      _corResultado = const Color(0xFFFF4757);
      _frasesDetectadas = [
        '⚠️ "Sua conta será bloqueada em 24h"',
        '⚠️ "Clique aqui para evitar o cancelamento"',
        '⚠️ "Transfira agora via PIX"',
      ];
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
          'Analisar Print',
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
                border: Border.all(color: const Color(0xFF7B2FBE).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF7B2FBE), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Envie um print de conversa, SMS ou e-mail para a IA identificar tentativas de golpe.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _simularSelecaoImagem,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imagemSelecionada ? const Color(0xFF7B2FBE) : Colors.white24,
                    width: 2,
                  ),
                ),
                child: _imagemSelecionada
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Color(0xFF7B2FBE), size: 60),
                          SizedBox(height: 8),
                          Text('Print selecionado ✓', style: TextStyle(color: Color(0xFF7B2FBE), fontWeight: FontWeight.bold)),
                          Text('Toque para trocar', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_rounded, color: Colors.white38, size: 60),
                          SizedBox(height: 8),
                          Text('Toque para selecionar o print', style: TextStyle(color: Colors.white54)),
                          Text('JPG, PNG ou PDF', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_imagemSelecionada && !_analisando) ? _analisarPrint : null,
                icon: _analisando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A2E)))
                    : const Icon(Icons.psychology),
                label: Text(_analisando ? 'IA Analisando...' : 'Analisar com IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2FBE),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dangerous, color: _corResultado, size: 32),
                        const SizedBox(width: 12),
                        Text(_resultado!, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _corResultado)),
                      ],
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
                    Text('${(_score * 100).toInt()}% de periculosidade', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 20),
                    const Text('Frases suspeitas detectadas:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    ..._frasesDetectadas.map(
                      (frase) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _corResultado.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _corResultado.withOpacity(0.3)),
                        ),
                        child: Text(frase, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🛡️ Orientação: Não clique em links, não transfira dinheiro e bloqueie o contato. Em caso de dúvida, ligue diretamente para a instituição.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
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