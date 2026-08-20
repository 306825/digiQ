import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Struttech logo mark — two bold parallel struts with a connecting node.
///
/// [dark] = true  → white mark on transparent (for use on blue/gradient surfaces)
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
        child: CustomPaint(painter: _StrutPainter(Colors.white)),
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
      child: CustomPaint(painter: _StrutPainter(Colors.white)),
    );
  }
}

class _StrutPainter extends CustomPainter {
  final Color color;
  const _StrutPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.13;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ── Left strut: diagonal line top-left → bottom-centre ──
    final leftTop = Offset(w * 0.18, h * 0.15);
    final leftBot = Offset(w * 0.38, h * 0.85);
    canvas.drawLine(leftTop, leftBot, paint);

    // ── Right strut: diagonal line top-centre → bottom-right ──
    final rightTop = Offset(w * 0.52, h * 0.15);
    final rightBot = Offset(w * 0.82, h * 0.85);
    canvas.drawLine(rightTop, rightBot, paint);

    // ── Crossbar connecting the two struts at mid-height ──
    final crossLeft = Offset(w * 0.28, h * 0.50);
    final crossRight = Offset(w * 0.67, h * 0.50);
    canvas.drawLine(crossLeft, crossRight, paint);

    // ── Node dot at crossbar centre ──
    final nodeR = sw * 0.65;
    final nodeCentre = Offset((crossLeft.dx + crossRight.dx) / 2, h * 0.50);
    canvas.drawCircle(nodeCentre, nodeR, fillPaint);
  }

  @override
  bool shouldRepaint(_StrutPainter old) => old.color != color;
}
