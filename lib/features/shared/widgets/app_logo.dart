import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Struttech S-road logo mark.
///
/// White S-shaped road on blue background with orange dashes and pins.
/// [dark] = true  → no container (caller provides the blue background)
/// [dark] = false → blue rounded container with shadow
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(painter: _SRoadPainter());

    if (dark) {
      return SizedBox(width: size, height: size, child: painter);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.40),
            blurRadius: size * 0.30,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.10),
        child: painter,
      ),
    );
  }
}

class _SRoadPainter extends CustomPainter {
  static const _orange = Color(0xFFFF7020);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadWidth = w * 0.20;

    // ── S-curve centre path ──────────────────────────────────
    final path = Path();
    path.moveTo(w * 0.15, h * 0.84);
    path.cubicTo(
      w * 0.92, h * 0.84,
      w * 0.92, h * 0.50,
      w * 0.50, h * 0.50,
    );
    path.cubicTo(
      w * 0.08, h * 0.50,
      w * 0.08, h * 0.16,
      w * 0.85, h * 0.16,
    );

    // ── White road ───────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Orange dashes along centre ───────────────────────────
    final dashPaint = Paint()
      ..color = _orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.030
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      double pos = len * 0.04;
      while (pos < len * 0.96) {
        final end = math.min(pos + len * 0.055, len * 0.96);
        canvas.drawPath(metric.extractPath(pos, end), dashPaint);
        pos = end + len * 0.04;
      }
    }

    // ── Orange pins at each end ───────────────────────────────
    _drawPin(canvas, Offset(w * 0.15, h * 0.84), _orange, w * 0.105);
    _drawPin(canvas, Offset(w * 0.85, h * 0.16), _orange, w * 0.105);
  }

  void _drawPin(Canvas canvas, Offset c, Color color, double r) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    // Circle head
    canvas.drawCircle(c, r, fill);

    // Pointed tail downward
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.55, c.dy + r * 0.55)
        ..lineTo(c.dx + r * 0.55, c.dy + r * 0.55)
        ..lineTo(c.dx, c.dy + r * 1.70)
        ..close(),
      fill,
    );

    // Inner white dot
    canvas.drawCircle(
      c,
      r * 0.38,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SRoadPainter old) => false;
}
