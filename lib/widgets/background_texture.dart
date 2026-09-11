import 'package:flutter/material.dart';

/// Textura de fundo decorativa do ProvaLab.
///
/// Widget reutilizável e independente: apenas pinta formas suaves
/// (pontos, círculos e curvas) atrás do conteúdo da tela, usando a
/// mesma paleta lilás já existente no app, em opacidade baixa.
///
/// Uso:
/// ```dart
/// Stack(
///   children: [
///     const Positioned.fill(child: AppBackgroundTexture()),
///     // ... resto do conteúdo da tela, normalmente
///   ],
/// )
/// ```
/// O widget não intercepta toques (CustomPaint não captura gestos),
/// então pode ficar atrás de qualquer conteúdo interativo sem
/// atrapalhar cliques, scroll, etc.
class AppBackgroundTexture extends StatelessWidget {
  const AppBackgroundTexture({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BackgroundTexturePainter(),
      ),
    );
  }
}

class _BackgroundTexturePainter extends CustomPainter {
  // Paleta usada exclusivamente pela textura (mesma família de cor
  // já existente no app, apenas em tons/opacidades mais suaves).
  static const Color _fundoBase = Color(0xFFF7F5FF);
  static const Color _lilasClaro = Color(0xFFEDE9FE);
  static const Color _lilasMedio = Color(0xFFDDD6FE);
  static const Color _roxoDetalhe = Color(0xFF8B5CF6);

  @override
  void paint(Canvas canvas, Size size) {
    // Fundo base sólido.
    final bgPaint = Paint()..color = _fundoBase;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final w = size.width;
    final h = size.height;

    // --- Círculos grandes e muito suaves, próximos das bordas ---
    _drawSoftCircle(
      canvas,
      center: Offset(w * 0.92, h * 0.06),
      radius: w * 0.22,
      color: _lilasClaro.withValues(alpha: 0.55),
    );
    _drawSoftCircle(
      canvas,
      center: Offset(w * -0.05, h * 0.28),
      radius: w * 0.20,
      color: _lilasMedio.withValues(alpha: 0.40),
    );
    _drawSoftCircle(
      canvas,
      center: Offset(w * 0.85, h * 0.62),
      radius: w * 0.16,
      color: _lilasClaro.withValues(alpha: 0.45),
    );
    _drawSoftCircle(
      canvas,
      center: Offset(w * 0.08, h * 0.85),
      radius: w * 0.24,
      color: _lilasMedio.withValues(alpha: 0.35),
    );

    // --- Curva abstrata fina, atravessando parte da tela ---
    final curvePaint = Paint()
      ..color = _roxoDetalhe.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final curvePath = Path()
      ..moveTo(w * -0.05, h * 0.42)
      ..quadraticBezierTo(
        w * 0.35, h * 0.30,
        w * 0.70, h * 0.48,
      )
      ..quadraticBezierTo(
        w * 0.90, h * 0.58,
        w * 1.05, h * 0.50,
      );
    canvas.drawPath(curvePath, curvePaint);

    // --- Pontos pequenos espalhados de forma irregular ---
    final dotSpecs = <_DotSpec>[
      _DotSpec(0.18, 0.12, 3.0, _roxoDetalhe, 0.10),
      _DotSpec(0.62, 0.08, 2.2, _roxoDetalhe, 0.08),
      _DotSpec(0.30, 0.22, 2.6, _lilasMedio, 0.60),
      _DotSpec(0.75, 0.30, 3.4, _roxoDetalhe, 0.07),
      _DotSpec(0.50, 0.38, 2.0, _lilasMedio, 0.50),
      _DotSpec(0.12, 0.55, 2.8, _roxoDetalhe, 0.09),
      _DotSpec(0.90, 0.46, 2.2, _lilasClaro, 0.70),
      _DotSpec(0.40, 0.68, 3.0, _roxoDetalhe, 0.06),
      _DotSpec(0.68, 0.78, 2.4, _lilasMedio, 0.55),
      _DotSpec(0.22, 0.90, 2.6, _roxoDetalhe, 0.08),
      _DotSpec(0.85, 0.88, 2.0, _lilasClaro, 0.65),
    ];

    for (final dot in dotSpecs) {
      final paint = Paint()..color = dot.color.withValues(alpha: dot.opacity);
      canvas.drawCircle(
        Offset(w * dot.dx, h * dot.dy),
        dot.radius,
        paint,
      );
    }

    // --- Forma geométrica arredondada, bem discreta, canto inferior ---
    final squarePaint = Paint()
      ..color = _lilasClaro.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.95, h * 0.94),
        width: w * 0.12,
        height: w * 0.12,
      ),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(rrect, squarePaint);
  }

  void _drawSoftCircle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundTexturePainter oldDelegate) => false;
}

class _DotSpec {
  final double dx;
  final double dy;
  final double radius;
  final Color color;
  final double opacity;

  const _DotSpec(this.dx, this.dy, this.radius, this.color, this.opacity);
}