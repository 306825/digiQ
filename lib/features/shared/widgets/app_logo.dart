import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Struttech logo — navigation route mark on midnight-blue background.
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF1B3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1628).withValues(alpha: 0.60),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.11),
        child: CustomPaint(painter: _RoutePainter()),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  static const _gold = Color(0xFFFFB300);
  static const _white = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rw = w * 0.16;

    // ── Smooth S-curve ────────────────────────────────────────
    final path = Path()
      ..moveTo(w * 0.18, h * 0.82)
      ..cubicTo(w * 0.85, h * 0.82, w * 0.85, h * 0.50, w * 0.50, h * 0.50)
      ..cubicTo(w * 0.15, h * 0.50, w * 0.15, h * 0.18, w * 0.82, h * 0.18);

    // White road
    canvas.drawPath(
      path,
      Paint()
        ..color = _white
        ..style = PaintingStyle.stroke
        ..strokeWidth = rw
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Gold dashes along centre
    final dashPaint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.026
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      final len = metric.length;
      double pos = len * 0.05;
      while (pos < len * 0.95) {
        final end = math.min(pos + len * 0.05, len * 0.95);
        canvas.drawPath(metric.extractPath(pos, end), dashPaint);
        pos = end + len * 0.04;
      }
    }

    // ── Origin marker — gold ring with white centre ───────────
    final origin = Offset(w * 0.18, h * 0.82);
    canvas.drawCircle(origin, rw * 0.65, Paint()..color = _gold);
    canvas.drawCircle(origin, rw * 0.32, Paint()..color = _white);

    // ── Destination pin — white teardrop with gold centre ─────
    _drawPin(canvas, Offset(w * 0.82, h * 0.18), rw * 0.72);
  }

  void _drawPin(Canvas canvas, Offset c, double r) {
    // White outer
    canvas.drawCircle(c, r, Paint()..color = _white);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - r * 0.58, c.dy + r * 0.55)
        ..lineTo(c.dx + r * 0.58, c.dy + r * 0.55)
        ..lineTo(c.dx, c.dy + r * 1.70)
        ..close(),
      Paint()..color = _white,
    );
    // Gold inner dot
    canvas.drawCircle(c, r * 0.40, Paint()..color = _gold);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => false;
}
