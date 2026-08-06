import 'dart:math' as math;
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Rizev slanted-infinity logo mark.
///
/// [dark] = true  → white symbol, transparent background (for dark/blue surfaces)
/// [dark] = false → white symbol inside blue gradient container (for light surfaces)
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
        child: CustomPaint(painter: _InfinityPainter(Colors.white)),
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
      child: CustomPaint(painter: _InfinityPainter(Colors.white)),
    );
  }
}

class _InfinityPainter extends CustomPainter {
  final Color color;
  const _InfinityPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);

    // Proportions — all relative to s so the logo scales perfectly
    final sw = s * 0.075; // stroke width
    final w  = s * 0.355; // half-width to each lobe tip
    final h  = s * 0.175; // half-height of each lobe
    final c1 = s * 0.120; // inner bezier control offset x
    final c2 = s * 0.230; // mid bezier control offset x
    final c3 = s * 0.475; // outer bezier control offset x (gives round outside)

    // Slanted ∞: two crossing bezier lobes, drawn at origin then rotated -22°
    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(-c1, -h, -c2, -h, -w,  0)  // upper arc, left lobe
      ..cubicTo(-c3,  h, -c1,  h,  0,  0)  // lower arc, left lobe → back to centre
      ..cubicTo( c1, -h,  c2, -h,  w,  0)  // upper arc, right lobe
      ..cubicTo( c3,  h,  c1,  h,  0,  0)  // lower arc, right lobe → back to centre
      ..close();

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-22 * math.pi / 180);

    canvas.drawPath(path, strokePaint);

    // Origin dot (left lobe tip) and destination dot (right lobe tip)
    final dotR = sw * 0.80;
    canvas.drawCircle(Offset(-w, 0), dotR, dotPaint);
    canvas.drawCircle(Offset( w, 0), dotR, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_InfinityPainter old) => old.color != color;
}
