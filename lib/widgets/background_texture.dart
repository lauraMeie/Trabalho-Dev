import 'package:flutter/material.dart';

/// Textura de fundo decorativa do ProvaLab.
///
/// Widget reutilizável e independente: pinta duas formas suaves e
/// desfocadas atrás do conteúdo da tela, na cor roxa do app, em
/// opacidade bem baixa — mantém o fundo praticamente neutro.
///
/// Uso:
/// ```dart
/// Stack(
///   children: [
///     const Positioned.fill(child: AppBackgroundTexture()),
///     // ... resto do conteúdo da tela
///   ],
/// )
/// ```
/// O widget não intercepta toques (CustomPaint não captura gestos).
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
  static const Color _fundoBase = Color(0xFFFAFAF9);
  static const Color _roxoSuave = Color(0xFF534AB7);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = _fundoBase;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final w = size.width;
    final h = size.height;

    _drawSoftCircle(
      canvas,
      center: Offset(w * 0.95, h * 0.04),
      radius: w * 0.30,
      color: _roxoSuave.withValues(alpha: 0.05),
    );

    _drawSoftCircle(
      canvas,
      center: Offset(w * -0.10, h * 0.92),
      radius: w * 0.32,
      color: _roxoSuave.withValues(alpha: 0.04),
    );
  }

  void _drawSoftCircle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundTexturePainter oldDelegate) => false;
}