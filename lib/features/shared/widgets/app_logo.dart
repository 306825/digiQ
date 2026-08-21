import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Struttech S-road logo mark.
///
/// [dark] = true  → white S on transparent  (splash / blue-gradient surfaces)
/// [dark] = false → full-colour S in white rounded container (light surfaces)
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
        child: CustomPaint(painter: _SRoadPainter(colorful: false)),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.30,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.10),
        child: CustomPaint(painter: _SRoadPainter(colorful: true)),
      ),
    );
  }
}

class _SRoadPainter extends CustomPainter {
  final bool colorful;
  const _SRoadPainter({required this.colorful});

  static const _roadBlue = Color(0xFF1A35D4);
  static const _roadDark = Color(0xFF1E1E30);
  static const _pinBlue = Color(0xFF1E40D8);
  static const _pinGreen = Color(0xFF26C59A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadWidth = w * 0.21;

    // ── S-curve path ─────────────────────────────────────────
    final path = Path();
    path.moveTo(w * 0.15, h * 0.82);
    path.cubicTo(
      w * 0.92, h * 0.82,
      w * 0.92, h * 0.50,
      w * 0.50, h * 0.50,
    );
    path.cubicTo(
      w * 0.08, h * 0.50,
      w * 0.08, h * 0.18,
      w * 0.85, h * 0.18,
    );

    // ── Road fill ────────────────────────────────────────────
    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (colorful) {
      roadPaint.shader = const LinearGradient(
        colors: [_roadBlue, _roadDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      roadPaint.color = Colors.white.withValues(alpha: 0.92);
    }

    canvas.drawPath(path, roadPaint);

    // ── Dashed centre line (colorful mode only) ───────────────
    if (colorful) {
      final dashPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.026
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
    }

    // ── Location pins ─────────────────────────────────────────
    // Blue pin — top right (destination)
    _drawPin(
      canvas,
      Offset(w * 0.85, h * 0.18),
      colorful ? _pinBlue : Colors.white,
      w * 0.095,
    );
    // Green pin — bottom left (origin)
    _drawPin(
      canvas,
      Offset(w * 0.15, h * 0.82),
      colorful ? _pinGreen : Colors.white.withValues(alpha: 0.70),
      w * 0.095,
    );
  }

  void _drawPin(Canvas canvas, Offset centre, Color color, double r) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    // Circle head
    canvas.drawCircle(centre, r, fill);

    // Pointed tail downward
    canvas.drawPath(
      Path()
        ..moveTo(centre.dx - r * 0.52, centre.dy + r * 0.52)
        ..lineTo(centre.dx + r * 0.52, centre.dy + r * 0.52)
        ..lineTo(centre.dx, centre.dy + r * 1.65)
        ..close(),
      fill,
    );

    // Inner white dot
    canvas.drawCircle(
      centre,
      r * 0.38,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SRoadPainter old) => old.colorful != colorful;
}
