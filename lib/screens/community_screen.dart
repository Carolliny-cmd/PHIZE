import 'package:flutter/material.dart';

/// Categorias de golpe reportado.
enum CategoriaGolpe {
  phishing('Phishing / Link falso', Icons.link_off, Color(0xFF00D4FF)),
  whatsapp('Golpe no WhatsApp', Icons.chat_bubble, Color(0xFF00B894)),
  financeiro('Golpe financeiro', Icons.account_balance_wallet, Color(0xFFFFA502)),
  emprego('Falsa vaga de emprego', Icons.work, Color(0xFF7B2FBE)),
  premio('Falso prêmio/sorteio', Icons.card_giftcard, Color(0xFFFF4757)),
  outro('Outro', Icons.report_problem, Colors.white54);

  final String rotulo;
  final IconData icone;
  final Color cor;

  const CategoriaGolpe(this.rotulo, this.icone, this.cor);
}

class GolpeReportado {
  final String titulo;
  final String descricao;
  final CategoriaGolpe categoria;
  final DateTime data;
  int confirmacoes;

  GolpeReportado({
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.data,
    this.confirmacoes = 0,
  });
}

String _tempoRelativo(DateTime data) {
  final diferenca = DateTime.now().difference(data);
  if (diferenca.inMinutes < 1) return 'agora mesmo';
  if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inHours < 24) return 'há ${diferenca.inHours}h';
  if (diferenca.inDays == 1) return 'ontem';
  return 'há ${diferenca.inDays} dias';
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  CategoriaGolpe? _filtro;

  final List<GolpeReportado> _golpes = [
    GolpeReportado(
      titulo: 'Falso suporte técnico bancário',
      descricao:
          'Ligação se passando por central do banco, pedindo código de segurança enviado por SMS para "cancelar uma compra suspeita".',
      categoria: CategoriaGolpe.financeiro,
      data: DateTime.now().subtract(const Duration(hours: 3)),
      confirmacoes: 24,
    ),
    GolpeReportado(
      titulo: 'Link de prêmio falso no WhatsApp',
      descricao:
          'Mensagem avisando que o número ganhou um vale-compras, com link para "resgatar" que pede dados pessoais e cartão.',
      categoria: CategoriaGolpe.premio,
      data: DateTime.now().subtract(const Duration(days: 1)),
      confirmacoes: 41,
    ),
    GolpeReportado(
      titulo: 'Vaga de emprego home office suspeita',
      descricao:
          'Anúncio prometendo salário alto por poucas horas de trabalho, mas pede pagamento antecipado por "material de treinamento".',
      categoria: CategoriaGolpe.emprego,
      data: DateTime.now().subtract(const Duration(days: 3)),
      confirmacoes: 9,
    ),
  ];

  List<GolpeReportado> get _golpesFiltrados {
    final lista = _filtro == null
        ? _golpes
        : _golpes.where((g) => g.categoria == _filtro).toList();
    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista;
  }

  void _abrirFormularioReport() {
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();
    CategoriaGolpe categoriaSelecionada = CategoriaGolpe.phishing;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Limita a altura do modal para caber em telas pequenas e
            // permite que o conteúdo role em vez de estourar (overflow)
            // o rodapé quando o teclado abre ou a tela é curta.
            final alturaMaxima = MediaQuery.of(context).size.height * 0.9;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: alturaMaxima),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alça de arraste (indica visualmente que o modal rola)
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.flag, color: Color(0xFF00B894)),
                        SizedBox(width: 8),
                        Text(
                          'Reportar golpe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Categoria
                    const Text(
                      'Categoria',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CategoriaGolpe.values.map((cat) {
                        final selecionado = categoriaSelecionada == cat;
                        return ChoiceChip(
                          label: Text(cat.rotulo),
                          selected: selecionado,
                          onSelected: (_) {
                            setModalState(() => categoriaSelecionada = cat);
                          },
                          avatar: Icon(cat.icone,
                              size: 16,
                              color: selecionado
                                  ? const Color(0xFF1A1A2E)
                                  : cat.cor),
                          labelStyle: TextStyle(
                            color: selecionado
                                ? const Color(0xFF1A1A2E)
                                : Colors.white70,
                            fontSize: 12,
                          ),
                          selectedColor: cat.cor,
                          backgroundColor: const Color(0xFF1A1A2E),
                          side: BorderSide(color: cat.cor.withOpacity(0.4)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Título
                    TextField(
                      controller: tituloController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Título curto',
                        labelStyle: const TextStyle(color: Colors.white54),
                        hintText: 'Ex: Falso e-mail dos Correios',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descrição
                    TextField(
                      controller: descricaoController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'O que aconteceu?',
                        labelStyle: const TextStyle(color: Colors.white54),
                        hintText:
                            'Descreva como o golpe funcionou, o que pediram, etc.',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF1A1A2E),
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
                        onPressed: () {
                          if (tituloController.text.trim().isEmpty ||
                              descricaoController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Preencha o título e a descrição.'),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _golpes.insert(
                              0,
                              GolpeReportado(
                                titulo: tituloController.text.trim(),
                                descricao: descricaoController.text.trim(),
                                categoria: categoriaSelecionada,
                                data: DateTime.now(),
                              ),
                            );
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Obrigado! Seu report ajuda a proteger outras pessoas.'),
                              backgroundColor: Color(0xFF00B894),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enviar report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final golpes = _golpesFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Comunidade', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioReport,
        backgroundColor: const Color(0xFF00B894),
        icon: const Icon(Icons.flag, color: Colors.white),
        label: const Text(
          'Reportar golpe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Resumo rápido
          Container(
            margin: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _EstatCard(numero: '${_golpes.length}', rotulo: 'Golpes\nreportados'),
                Container(width: 1, height: 36, color: Colors.white12),
                _EstatCard(
                  numero: '${_golpes.fold<int>(0, (soma, g) => soma + g.confirmacoes)}',
                  rotulo: 'Pessoas\nalertadas',
                ),
                Container(width: 1, height: 36, color: Colors.white12),
                const _EstatCard(numero: '24h', rotulo: 'Atualização\nconstante'),
              ],
            ),
          ),

          // Filtro por categoria
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _FiltroChip(
                  rotulo: 'Todos',
                  selecionado: _filtro == null,
                  cor: const Color(0xFF00D4FF),
                  onTap: () => setState(() => _filtro = null),
                ),
                const SizedBox(width: 8),
                ...CategoriaGolpe.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FiltroChip(
                      rotulo: cat.rotulo,
                      selecionado: _filtro == cat,
                      cor: cat.cor,
                      onTap: () => setState(() => _filtro = cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de golpes
          Expanded(
            child: golpes.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum golpe reportado nessa categoria ainda.',
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    itemCount: golpes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final golpe = golpes[index];
                      return _CardGolpe(
                        golpe: golpe,
                        onConfirmar: () {
                          setState(() => golpe.confirmacoes++);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EstatCard extends StatelessWidget {
  final String numero;
  final String rotulo;

  const _EstatCard({required this.numero, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          numero,
          style: const TextStyle(
            color: Color(0xFF00D4FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rotulo,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.2),
        ),
      ],
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String rotulo;
  final bool selecionado;
  final Color cor;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.rotulo,
    required this.selecionado,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selecionado ? cor : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withOpacity(selecionado ? 1 : 0.3)),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            color: selecionado ? const Color(0xFF1A1A2E) : Colors.white70,
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CardGolpe extends StatelessWidget {
  final GolpeReportado golpe;
  final VoidCallback onConfirmar;

  const _CardGolpe({required this.golpe, required this.onConfirmar});

  @override
  Widget build(BuildContext context) {
    final cor = golpe.categoria.cor;

    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(golpe.categoria.icone, color: cor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      golpe.categoria.rotulo,
                      style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _tempoRelativo(golpe.data),
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            golpe.titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            golpe.descricao,
            style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              InkWell(
                onTap: onConfirmar,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 14, color: Color(0xFF00B894)),
                      const SizedBox(width: 6),
                      Text(
                        'Aconteceu comigo (${golpe.confirmacoes})',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}