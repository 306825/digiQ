import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Rizec logo mark.
///
/// A backward-leaning L whose tail curves back around to form a closed loop —
/// reads as both a route (origin pin → corner waypoint → destination) and a
/// continuous journey. Rendered in an amber → deep-orange gradient that pops
/// against the app's blue backgrounds.
///
/// [dark] = true  → gradient mark on transparent bg (blue/dark surfaces)
/// [dark] = false → gradient mark inside blue gradient container (light surfaces)
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
        child: CustomPaint(painter: const _LoopPainter()),
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
      child: CustomPaint(painter: const _LoopPainter()),
    );
  }
}

class _LoopPainter extends CustomPainter {
  const _LoopPainter();

  // Amber → deep-orange: vivid against the app's blue palette
  static const _grad = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFF5722)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s  = math.min(size.width, size.height);
    final ox = (size.width  - s) / 2;
    final oy = (size.height - s) / 2;
    final sw = s * 0.105;

    final shader = _grad.createShader(Rect.fromLTWH(ox, oy, s, s));
    final stroke  = Paint()
      ..shader      = shader
      ..style       = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    final fill = Paint()
      ..shader = shader
      ..style  = PaintingStyle.fill;

    // ── Lean the whole shape 14° clockwise (backward lean) ──────
    canvas.save();
    canvas.translate(ox + s / 2, oy + s / 2); // pivot on icon centre
    canvas.rotate(14 * math.pi / 180);
    // All subsequent coords are centred at (0,0); icon spans ≈ ±s/2

    // ── Three key points of the backward L ──────────────────────
    final ax = -s * 0.27; final ay = -s * 0.21; // A — origin  (start of arm)
    final bx =  s * 0.27; final by = -s * 0.21; // B — corner  (the L-turn)
    final cx =  s * 0.27; final cy =  s * 0.21; // C — leg end (before arrowhead)
    final aLen = sw * 1.15;                       // arrow length
    final aHW  = sw * 0.72;                       // arrow half-width

    // Γ shape: arm (A→B) + leg (B→C) + sweeping loop curve (C→A)
    final path = Path()
      ..moveTo(ax, ay)
      ..lineTo(bx, by)                         // ── arm: goes right
      ..lineTo(cx, cy - aLen)                  // ── leg: goes down (stops before arrowhead)
      ..cubicTo(                               // ── loop sweep back to origin
        -s * 0.10, cy + s * 0.20,             //    cp1: dip below-left of C
        ax - s * 0.04, s * 0.08,             //    cp2: rise from lower-left
        ax, ay,                               //    land at A
      );

    canvas.drawPath(path, stroke);

    // ── Origin pin at A (larger filled circle) ───────────────────
    canvas.drawCircle(Offset(ax, ay), sw * 0.82, fill);

    // ── Waypoint dot at corner B ─────────────────────────────────
    canvas.drawCircle(Offset(bx, by), sw * 0.50, fill);

    // ── Destination arrowhead at C (pointing down along the leg) ─
    canvas.drawPath(
      Path()
        ..moveTo(cx,        cy)         // tip
        ..lineTo(cx - aHW, cy - aLen)   // base-left
        ..lineTo(cx + aHW, cy - aLen)   // base-right
        ..close(),
      fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoopPainter old) => false;
}
