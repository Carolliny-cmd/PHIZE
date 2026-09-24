import 'dart:async';
import 'package:flutter/material.dart';
import 'link_screen.dart';
import 'print_screen.dart';
import 'community_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final PageController _tipController = PageController();
  Timer? _tipTimer;
  int _tipIndex = 0;

  // ---- Dados de demonstração (fake) ----
  // Quando houver backend, troque estas listas por dados reais.

  final List<Map<String, dynamic>> _estatisticas = const [
    {'icon': Icons.link, 'valor': '12', 'label': 'Links\nverificados', 'cor': Color(0xFF00D4FF)},
    {'icon': Icons.image_search, 'valor': '3', 'label': 'Prints\nanalisados', 'cor': Color(0xFF7B2FBE)},
    {'icon': Icons.shield, 'valor': '5', 'label': 'Golpes\nevitados', 'cor': Color(0xFF00B894)},
    {'icon': Icons.calendar_today, 'valor': '14', 'label': 'Dias\nativo', 'cor': Color(0xFFFFA502)},
  ];

  final List<Map<String, dynamic>> _dicas = const [
    {
      'icon': Icons.security,
      'texto': 'Bancos nunca pedem sua senha ou código por WhatsApp ou SMS.',
    },
    {
      'icon': Icons.link_off,
      'texto': 'Desconfie de links curtos ou muito urgentes enviados por desconhecidos.',
    },
    {
      'icon': Icons.verified_user,
      'texto': 'Ative a autenticação em duas etapas em todas as suas contas importantes.',
    },
    {
      'icon': Icons.phone_disabled,
      'texto': 'Golpistas criam urgência de propósito para você não pensar antes de agir.',
    },
  ];

  final List<Map<String, dynamic>> _verificacoesRecentes = const [
    {
      'icon': Icons.link,
      'titulo': 'Link analisado',
      'resultado': 'Seguro',
      'cor': Colors.greenAccent,
      'tempo': 'há 2h',
    },
    {
      'icon': Icons.image_search,
      'titulo': 'Print analisado',
      'resultado': 'Suspeito',
      'cor': Color(0xFFFFA502),
      'tempo': 'há 1 dia',
    },
    {
      'icon': Icons.link,
      'titulo': 'Link analisado',
      'resultado': 'Seguro',
      'cor': Colors.greenAccent,
      'tempo': 'há 3 dias',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Avança a dica de segurança automaticamente a cada 5 segundos.
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final proximo = (_tipIndex + 1) % _dicas.length;
      _tipController.animateToPage(
        proximo,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tipTimer?.cancel();
    _tipController.dispose();
    super.dispose();
  }

  // Fade + slide com pequeno atraso (index), para os blocos entrarem em sequência.
  Animation<double> _fadeFor(int index) {
    final start = (0.06 * index).clamp(0.0, 0.7);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.shield, color: Color(0xFF00D4FF), size: 24),
            SizedBox(width: 8),
            Text(
              'PHIZE',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.06),
              child: const Icon(Icons.person, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saudação
            FadeTransition(
              opacity: _fadeFor(0),
              child: const Text(
                'Olá, Guardião! 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FadeTransition(
              opacity: _fadeFor(0),
              child: const Text(
                'O que deseja verificar hoje?',
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),

            // Atalho de emergência
            FadeTransition(
              opacity: _fadeFor(1),
              child: _EmergencyBanner(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmergencyScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Estatísticas pessoais
            FadeTransition(
              opacity: _fadeFor(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suas estatísticas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: _estatisticas
                        .map((e) => _StatCard(
                              icone: e['icon'] as IconData,
                              valor: e['valor'] as String,
                              label: e['label'] as String,
                              cor: e['cor'] as Color,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Dica de segurança do dia (rotativa)
            FadeTransition(
              opacity: _fadeFor(3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dica de segurança',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 104,
                    child: PageView.builder(
                      controller: _tipController,
                      itemCount: _dicas.length,
                      onPageChanged: (i) => setState(() => _tipIndex = i),
                      itemBuilder: (context, i) {
                        final dica = _dicas[i];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF00D4FF).withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(dica['icon'] as IconData,
                                  color: const Color(0xFF00D4FF), size: 28),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  dica['texto'] as String,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_dicas.length, (i) {
                      final ativo = i == _tipIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: ativo ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ativo
                              ? const Color(0xFF00D4FF)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Ações principais
            FadeTransition(
              opacity: _fadeFor(4),
              child: const Text(
                'Verificar agora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _fadeFor(4),
              child: _CardAnalise(
                icone: Icons.link,
                titulo: 'Analisar Link',
                descricao: 'Verifique se uma URL é segura ou maliciosa',
                cor: const Color(0xFF00D4FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LinkScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeFor(5),
              child: _CardAnalise(
                icone: Icons.image_search,
                titulo: 'Analisar Print',
                descricao: 'Envie um print de conversa para a IA analisar',
                cor: const Color(0xFF7B2FBE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrintScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeFor(6),
              child: _CardAnalise(
                icone: Icons.people,
                titulo: 'Comunidade',
                descricao: 'Veja golpes reportados por outros usuários',
                cor: const Color(0xFF00B894),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CommunityScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Últimas verificações
            FadeTransition(
              opacity: _fadeFor(7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Últimas verificações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _verificacoesRecentes.length; i++) ...[
                          _VerificacaoTile(item: _verificacoesRecentes[i]),
                          if (i != _verificacoesRecentes.length - 1)
                            const Divider(height: 1, color: Colors.white12),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Termômetro de risco
            FadeTransition(
              opacity: _fadeFor(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFFF4757), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Nível de Ameaça Atual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF4757).withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ALTO',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF4757),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 0.78),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 12,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF4757),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '78% de tentativas de golpe registradas hoje',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _EmergencyBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _EmergencyBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4757), Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4757).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.report_problem_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fui vítima de um golpe agora',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Toque aqui para o passo a passo de emergência',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icone;
  final String valor;
  final String label;
  final Color cor;

  const _StatCard({
    required this.icone,
    required this.valor,
    required this.label,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: cor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificacaoTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _VerificacaoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cor = item['cor'] as Color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(item['icon'] as IconData, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['titulo'] as String,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            item['tempo'] as String,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item['resultado'] as String,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardAnalise extends StatefulWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final Color cor;
  final VoidCallback onTap;

  const _CardAnalise({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.cor,
    required this.onTap,
  });

  @override
  State<_CardAnalise> createState() => _CardAnaliseState();
}

class _CardAnaliseState extends State<_CardAnalise> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressionado ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressionado = true),
          onTapCancel: () => setState(() => _pressionado = false),
          onTapUp: (_) => setState(() => _pressionado = false),
          borderRadius: BorderRadius.circular(16),
          splashColor: widget.cor.withOpacity(0.12),
          highlightColor: widget.cor.withOpacity(0.06),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.cor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.cor.withOpacity(0.25),
                        widget.cor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icone, color: widget.cor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.descricao,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: widget.cor, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}