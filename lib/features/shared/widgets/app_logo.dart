import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Rizec logo mark — a Z-shaped route path.
///
/// The Z encodes the "Z" in Rizec while reading as a route map:
/// origin pin (top-left) → waypoint → diagonal route → waypoint → destination (bottom-right).
///
/// [dark] = true  → white mark on transparent bg (for dark/blue surfaces)
/// [dark] = false → white mark inside blue gradient container (for light surfaces)
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ZRoutePainter(Colors.white)),
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
      child: CustomPaint(painter: _ZRoutePainter(Colors.white)),
    );
  }
}

class _ZRoutePainter extends CustomPainter {
  final Color color;
  const _ZRoutePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s   = math.min(size.width, size.height);
    final ox  = (size.width  - s) / 2;
    final oy  = (size.height - s) / 2;
    final sw  = s * 0.105;
    final dot = sw * 0.78;

    // ── Four Z-corners ──────────────────────────────────────────
    final p1 = Offset(ox + s * 0.13, oy + s * 0.23); // top-left  (origin)
    final p2 = Offset(ox + s * 0.87, oy + s * 0.23); // top-right (waypoint)
    final p3 = Offset(ox + s * 0.13, oy + s * 0.77); // bot-left  (waypoint)
    // p4 = bottom-right tip is the arrowhead, path stops just before it
    final p4end = Offset(ox + s * 0.77, oy + s * 0.77);
    final p4tip = Offset(ox + s * 0.90, oy + s * 0.77);

    // ── Z route path ────────────────────────────────────────────
    // Top horizontal → subtly curved diagonal → bottom horizontal
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..cubicTo(
        p2.dx - s * 0.20, p2.dy + s * 0.20,
        p3.dx + s * 0.20, p3.dy - s * 0.20,
        p3.dx, p3.dy,
      )
      ..lineTo(p4end.dx, p4end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color  = color
        ..style  = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap   = StrokeCap.round
        ..strokeJoin  = StrokeJoin.round,
    );

    final fill = Paint()..color = color..style = PaintingStyle.fill;

    // ── Origin pin at p1 (larger filled circle) ─────────────────
    canvas.drawCircle(p1, dot, fill);

    // ── Waypoint dots at p2 and p3 (smaller) ────────────────────
    canvas.drawCircle(p2, dot * 0.58, fill);
    canvas.drawCircle(p3, dot * 0.58, fill);

    // ── Destination arrowhead at p4 pointing right ──────────────
    final aLen = sw * 1.25;
    final aHW  = sw * 0.82;
    canvas.drawPath(
      Path()
        ..moveTo(p4tip.dx, p4tip.dy)
        ..lineTo(p4tip.dx - aLen, p4tip.dy - aHW)
        ..lineTo(p4tip.dx - aLen, p4tip.dy + aHW)
        ..close(),
      fill,
    );
  }

  @override
  bool shouldRepaint(_ZRoutePainter old) => old.color != color;
}
