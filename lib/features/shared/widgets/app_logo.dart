import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Struttech S-road logo mark.
/// White S on blue gradient background with gold road dashes and pins.
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(painter: _SRoadPainter());

    if (dark) {
      // On blue splash background — no container, paint directly
      return SizedBox(width: size, height: size, child: mark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.45),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: mark,
      ),
    );
  }
}

class _SRoadPainter extends CustomPainter {
  static const _gold = Color(0xFFFFB300);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadWidth = w * 0.21;

    // ── S-curve centre path ──────────────────────────────────
    final path = Path();
    path.moveTo(w * 0.14, h * 0.84);
    path.cubicTo(
      w * 0.92, h * 0.84,
      w * 0.92, h * 0.50,
      w * 0.50, h * 0.50,
    );
    path.cubicTo(
      w * 0.08, h * 0.50,
      w * 0.08, h * 0.16,
      w * 0.86, h * 0.16,
    );

    // ── White S road ─────────────────────────────────────────
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Gold dashes along centre ──────────────────────────────
    final dashPaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
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

    // ── Gold pins at each end ─────────────────────────────────
    _drawPin(canvas, Offset(w * 0.14, h * 0.84), w * 0.10);
    _drawPin(canvas, Offset(w * 0.86, h * 0.16), w * 0.10);
  }

  void _drawPin(Canvas canvas, Offset c, double r) {
    final fill = Paint()..color = _gold..style = PaintingStyle.fill;

    // Circle head
    canvas.drawCircle(c, r, fill);

    // Pointed tail downward
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.55, c.dy + r * 0.55)
        ..lineTo(c.dx + r * 0.55, c.dy + r * 0.55)
        ..lineTo(c.dx, c.dy + r * 1.65)
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
