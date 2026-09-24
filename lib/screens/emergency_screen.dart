import 'package:flutter/material.dart';

/// Tela de passo a passo exibida quando o usuário toca no atalho
/// de emergência na home ("Fui vítima de um golpe agora").
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static final List<_Passo> _passos = [
    _Passo(
      icone: Icons.self_improvement,
      titulo: 'Mantenha a calma',
      descricao:
          'Respire fundo. Agir rápido é importante, mas decisões com calma evitam novos erros.',
    ),
    _Passo(
      icone: Icons.credit_card_off,
      titulo: 'Bloqueie cartões e contas',
      descricao:
          'Ligue para o seu banco imediatamente e bloqueie cartões, PIX ou contas que possam ter sido comprometidos.',
    ),
    _Passo(
      icone: Icons.password,
      titulo: 'Troque suas senhas',
      descricao:
          'Altere a senha de e-mail, bancos e redes sociais o quanto antes, começando pelas contas mais sensíveis.',
    ),
    _Passo(
      icone: Icons.verified_user_outlined,
      titulo: 'Ative a autenticação em duas etapas',
      descricao:
          'Adicione uma camada extra de segurança nas contas afetadas para dificultar novos acessos indevidos.',
    ),
    _Passo(
      icone: Icons.description_outlined,
      titulo: 'Registre um Boletim de Ocorrência',
      descricao:
          'Muitos estados permitem registrar o B.O. online. Isso ajuda em disputas com bancos e lojas.',
    ),
    _Passo(
      icone: Icons.groups_outlined,
      titulo: 'Denuncie na comunidade Phize',
      descricao:
          'Compartilhe o golpe na aba Comunidade para alertar outras pessoas e ajudar a evitar novas vítimas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Ajuda de Emergência',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4757), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: const [
                Icon(Icons.shield_moon_outlined, color: Colors.white, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Siga os passos abaixo agora. Cada minuto conta para proteger '
                    'suas contas e seu dinheiro.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < _passos.length; i++) ...[
            _PassoCard(numero: i + 1, passo: _passos[i]),
            if (i != _passos.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _Passo {
  final IconData icone;
  final String titulo;
  final String descricao;

  const _Passo({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });
}

class _PassoCard extends StatelessWidget {
  final int numero;
  final _Passo passo;

  const _PassoCard({required this.numero, required this.passo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4757).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Color(0xFFFF4757),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Icon(passo.icone, color: const Color(0xFF00D4FF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passo.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  passo.descricao,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.35,
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