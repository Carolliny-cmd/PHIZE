import 'package:flutter/material.dart';
import 'dart:math';

class PhizeLogo extends StatefulWidget {
  final double size;
  final Offset? mousePosition; // Recebe a posição global do mouse da tela de login

  const PhizeLogo({super.key, this.size = 80, this.mousePosition});

  @override
  State<PhizeLogo> createState() => _PhizeLogoState();
}

class _PhizeLogoState extends State<PhizeLogo> with TickerProviderStateMixin {
  late AnimationController _controller;
  double _pupilX = 0;
  double _pupilY = 0;
  double _targetX = 0;
  double _targetY = 0;
  double _blink = 1;
  int _blinkState = 0;
  int _blinkTimer = 0;
  int _blinkCount = 0;
  int _waitTimer = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update)..repeat();
  }

  @override
  void didUpdateWidget(covariant PhizeLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalcula a rotação do olho de forma sutil quando o mouse mexe
    if (widget.mousePosition != oldWidget.mousePosition) {
      _atualizarPosicaoOlho();
    }
  }

  void _atualizarPosicaoOlho() {
    if (widget.mousePosition == null || !mounted) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    // Descobre onde a logo está na janela
    final logoPosition = box.localToGlobal(Offset.zero);
    final w = box.size.width;
    final h = box.size.height;

    // Centro do olho
    final cx = logoPosition.dx + w / 2;
    final cy = logoPosition.dy + h / 2;

    final dx = widget.mousePosition!.dx - cx;
    final dy = widget.mousePosition!.dy - cy;
    
    final angle = atan2(dy, dx);

    setState(() {
      // SUTIL: Área de movimento reduzida para a pupila não ir até as bordas
      _targetX = cos(angle) * 14; 
      _targetY = sin(angle) * 7;
    });
  }

  void _update() {
    setState(() {
      // SUTIL: Multiplicador reduzido para 0.05 para o arrasto ser lento e fluido
      _pupilX += (_targetX - _pupilX) * 0.05;
      _pupilY += (_targetY - _pupilY) * 0.05;

      // Lógica nativa de piscar os olhos (mantida intacta)
      _waitTimer++;
      if (_blinkState == 0) {
        _blink = 1;
        if (_waitTimer > 180) { _blinkState = 1; _waitTimer = 0; _blinkTimer = 0; }
      } else if (_blinkState == 1) {
        _blinkTimer++;
        _blink = max(0.02, 1 - _blinkTimer / 8);
        if (_blinkTimer >= 8) { _blinkState = 2; _blinkTimer = 0; }
      } else if (_blinkState == 2) {
        _blinkTimer++;
        _blink = min(1, _blinkTimer / 8);
        if (_blinkTimer >= 8) {
          _blink = 1;
          _blinkCount++;
          if (_blinkCount < 2) { _blinkState = 1; _blinkTimer = 0; }
          else { _blinkState = 0; _blinkTimer = 0; _blinkCount = 0; _waitTimer = 0; }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size * 0.5),
      painter: _OlhoPainter(_blink, _pupilX, _pupilY),
    );
  }
}

class _OlhoPainter extends CustomPainter {
  final double blink;
  final double pupilX;
  final double pupilY;

  _OlhoPainter(this.blink, this.pupilX, this.pupilY);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final rx = w * 0.5;
    final ry = h * 0.48;
    final px = cx + pupilX;
    final py = cy + pupilY;

    final path = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2 * blink));

    canvas.save();
    canvas.clipPath(path);

    // fundo
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF0D1B2A));

    // scanlines
    final scanPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.15)
      ..strokeWidth = 0.8;
    for (double y = 0; y < h; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(w, y), scanPaint);
    }

    // iris maior
    final irisRadius = h * 0.52;
    final irisGrad = Paint()
      ..shader = RadialGradient(
        colors: [const Color.fromARGB(255, 255, 0, 242), const Color(0xFF0033AA)],
      ).createShader(Rect.fromCircle(center: Offset(px, py), radius: irisRadius));
    canvas.drawCircle(Offset(px, py), irisRadius, irisGrad);

    // pupila maior
    final pupilaRadius = irisRadius * 0.52;
    canvas.drawCircle(Offset(px, py), pupilaRadius, Paint()..color = const Color(0xFF040810));

    // cruz tech
    final cruzPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.7)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(px, py - pupilaRadius), Offset(px, py + pupilaRadius), cruzPaint);
    canvas.drawLine(Offset(px - pupilaRadius, py), Offset(px + pupilaRadius, py), cruzPaint);

    // brilho
    canvas.drawCircle(
      Offset(px - pupilaRadius * 0.4, py - pupilaRadius * 0.4),
      pupilaRadius * 0.22,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    canvas.restore();

    // contorno
    final contornoPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2 * blink),
      contornoPaint,
    );

    // linhas laterais
    canvas.drawLine(Offset(cx - rx - 2, cy), Offset(cx - rx - 16, cy), contornoPaint);
    canvas.drawLine(Offset(cx + rx + 2, cy), Offset(cx + rx + 16, cy), contornoPaint);

    // cantos decorativos estáticos
    final cantoPaint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    void canto(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * 14, y), cantoPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * 14), cantoPaint);
    }
    canto(8, 4, 1, 1);
    canto(w - 8, 4, -1, 1);
    canto(8, h - 4, 1, -1);
    canto(w - 8, h - 4, -1, -1);
  }

  @override
  bool shouldRepaint(_OlhoPainter old) =>
      old.blink != blink || old.pupilX != pupilX || old.pupilY != pupilY;
}