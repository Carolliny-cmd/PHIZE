import 'package:flutter/material.dart';

class ComunidadeScreen extends StatelessWidget {
  const ComunidadeScreen({super.key});

  final List<Map<String, dynamic>> _alertas = const [
    {
      'titulo': 'Golpe do PIX - Falso Banco',
      'descricao': 'Mensagem pedindo confirmação de dados via link falso do banco.',
      'curtidas': 142,
      'tempo': '2h atrás',
      'perigo': 0.95,
      'tag': 'PIX',
    },
    {
      'titulo': 'Falsa promoção - iPhone grátis',
      'descricao': 'Site clonado da Apple pedindo dados do cartão para "pagar frete".',
      'curtidas': 89,
      'tempo': '5h atrás',
      'perigo': 0.88,
      'tag': 'Phishing',
    },
    {
      'titulo': 'Golpe do falso suporte técnico',
      'descricao': 'Ligação de falso técnico pedindo acesso remoto ao celular.',
      'curtidas': 67,
      'tempo': '1d atrás',
      'perigo': 0.82,
      'tag': 'Engenharia Social',
    },
    {
      'titulo': 'SMS falso dos Correios',
      'descricao': 'SMS com link para "liberar encomenda retida" cobrando taxa.',
      'curtidas': 54,
      'tempo': '2d atrás',
      'perigo': 0.79,
      'tag': 'SMS',
    },
    {
      'titulo': 'Falso emprego home office',
      'descricao': 'Oferta de emprego pedindo depósito para "kit de trabalho".',
      'curtidas': 38,
      'tempo': '3d atrás',
      'perigo': 0.71,
      'tag': 'Emprego',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Color(0xFF00D4FF)),
        title: const Text(
          'Comunidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF00D4FF)),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: const Color(0xFF1A1A2E),
        icon: const Icon(Icons.add),
        label: const Text('Reportar Golpe'),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _BotaoFiltro(label: '🔥 Em alta', ativo: true),
                const SizedBox(width: 8),
                _BotaoFiltro(label: '🕐 Recentes', ativo: false),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alertas.length,
              itemBuilder: (context, index) {
                final alerta = _alertas[index];
                final perigo = alerta['perigo'] as double;
                final cor = perigo >= 0.9
                    ? const Color(0xFFFF4757)
                    : perigo >= 0.7
                        ? const Color(0xFFFFA502)
                        : const Color(0xFF00B894);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(alerta['tag'], style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Text(alerta['tempo'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(alerta['titulo'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(alerta['descricao'], style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: perigo,
                                minHeight: 6,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(cor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                const Icon(Icons.thumb_up_outlined, color: Color(0xFF00D4FF), size: 18),
                                const SizedBox(width: 4),
                                Text('${alerta['curtidas']}', style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.share_outlined, color: Colors.white38, size: 18),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BotaoFiltro extends StatelessWidget {
  final String label;
  final bool ativo;

  const _BotaoFiltro({required this.label, required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ativo ? const Color(0xFF00D4FF).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ativo ? const Color(0xFF00D4FF) : Colors.white24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ativo ? const Color(0xFF00D4FF) : Colors.white54,
          fontSize: 13,
          fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}