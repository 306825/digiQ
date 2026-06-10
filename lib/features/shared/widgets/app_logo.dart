import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// The digiQ "Q" logo mark.
///
/// [dark] = true  → white Q mark with no background  (for use on blue/gradient surfaces)
/// [dark] = false → white Q mark inside blue gradient container (for use on light surfaces)
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    if (dark) {
      // Transparent — the caller's background provides the colour
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _QMarkPainter(Colors.white),
        ),
      );
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
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _QMarkPainter(Colors.white),
      ),
    );
  }
}

class _QMarkPainter extends CustomPainter {
  final Color color;
  const _QMarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.11;
    final cx = size.width * 0.43;
    final cy = size.height * 0.43;
    final r = size.width * 0.255;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── Circle (body of Q) ──────────────────────────────────
    // Draw 300° of arc, leaving a small gap at bottom-right where tail starts
    const startAngle = math.pi * 0.60; // ~108° — just past bottom-right
    const sweepAngle = math.pi * 1.70; // 306° sweep
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // ── Tail of Q ──────────────────────────────────────────
    // Starts where the arc ends (at startAngle on the circle edge),
    // extends diagonally to the bottom-right corner.
    final tailStart = Offset(
      cx + r * math.cos(startAngle) * 0.55,
      cy + r * math.sin(startAngle) * 0.55,
    );
    final tailEnd = Offset(
      cx + r * 1.25,
      cy + r * 1.25,
    );
    canvas.drawLine(tailStart, tailEnd, paint);
  }

  @override
  bool shouldRepaint(_QMarkPainter old) => old.color != color;
}
