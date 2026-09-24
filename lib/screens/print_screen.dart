import 'package:flutter/material.dart';

class PrintScreen extends StatefulWidget {
  const PrintScreen({super.key});

  @override
  State<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  bool _imagemSelecionada = false;
  bool _analisando = false;
  bool _resultadoPronto = false;

  // Simula a seleção de uma imagem (para demonstração/teste).
  // Quando o image_picker real for integrado, troque esta função
  // pela lógica de escolher a imagem de verdade.
  void _selecionarImagem() {
    setState(() {
      _imagemSelecionada = true;
      _resultadoPronto = false;
    });
  }

  void _removerImagem() {
    setState(() {
      _imagemSelecionada = false;
      _resultadoPronto = false;
    });
  }

  Future<void> _analisar() async {
    if (!_imagemSelecionada || _analisando) return;

    setState(() {
      _analisando = true;
      _resultadoPronto = false;
    });

    // Simula o tempo de processamento da IA.
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;
    setState(() {
      _analisando = false;
      _resultadoPronto = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Analisar Print',
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
              'Envie um print da conversa para a IA analisar',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // Área de seleção / preview da imagem
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _imagemSelecionada
                  ? _buildPreview()
                  : _buildSeletor(),
            ),

            const SizedBox(height: 24),

            // Botão analisar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _imagemSelecionada && !_analisando ? _analisar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2FBE),
                  disabledBackgroundColor:
                      const Color(0xFF7B2FBE).withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _analisando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Analisar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // Resultado simulado da análise
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _resultadoPronto
                  ? _buildResultado()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletor() {
    return InkWell(
      key: const ValueKey('seletor'),
      onTap: _selecionarImagem,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7B2FBE).withOpacity(0.4),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Color(0xFF7B2FBE),
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'Toque para selecionar um print',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      key: const ValueKey('preview'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B2FBE).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Miniatura simulada da imagem
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B2FBE), Color(0xFF00D4FF)],
              ),
            ),
            child: const Icon(Icons.image, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'print_conversa.png',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Imagem carregada',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removerImagem,
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.fact_check_outlined, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text(
                  'Resultado da análise',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhum indício de golpe foi identificado nesta conversa. '
              'De qualquer forma, evite compartilhar dados pessoais, '
              'senhas ou códigos recebidos por SMS.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag('Baixo risco', Colors.greenAccent),
                const SizedBox(width: 8),
                _buildTag('Confiança 92%', const Color(0xFF00D4FF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}