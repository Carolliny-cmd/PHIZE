import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/faixa_risco.dart';

/// Termômetro de Risco Visual (RF07): medidor em arco de 0 a 100, com as
/// cores do semáforo. Score e faixa são recebidos como parâmetro: o componente
/// não decide faixa nem calcula score.
class TermometroRisco extends StatelessWidget {
  const TermometroRisco({super.key, required this.score, required this.faixa});

  final int score;
  final FaixaRisco faixa;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 124,
          child: CustomPaint(
            painter: _ArcoPainter(
              fracao: score.clamp(0, 100) / 100,
              cor: faixa.cor,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                '$score',
                style: tema.headlineMedium?.copyWith(fontSize: 48, height: 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Score de Risco: $score/100', style: tema.bodySmall),
        const SizedBox(height: 4),
        Text(
          faixa.rotulo,
          style: tema.headlineSmall?.copyWith(
            color: faixa.corTextoEm(Theme.of(context).brightness),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ArcoPainter extends CustomPainter {
  const _ArcoPainter({required this.fracao, required this.cor});

  final double fracao;
  final Color cor;

  static const double _espessura = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final raio = size.width / 2 - _espessura / 2;
    final area = Rect.fromCircle(
      center: Offset(size.width / 2, size.width / 2),
      radius: raio,
    );
    Paint traco(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _espessura
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(area, math.pi, math.pi, false, traco(cor.withAlpha(45)));
    // Com score 0, um ponto marca o início da escala.
    canvas.drawArc(
      area,
      math.pi,
      math.max(math.pi * fracao, 0.001),
      false,
      traco(cor),
    );
  }

  @override
  bool shouldRepaint(_ArcoPainter antigo) =>
      antigo.fracao != fracao || antigo.cor != cor;
}
