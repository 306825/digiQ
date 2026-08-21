import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Struttech logo mark — matches the website nav logo.
/// White route path on blue background with a light-blue destination dot.
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(painter: _RoutePainter());

    if (dark) {
      // On the blue splash screen — wrap in the same blue container so
      // it reads identically everywhere.
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.26),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.14),
          child: mark,
        ),
      );
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
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.45),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.14),
        child: mark,
      ),
    );
  }
}

/// Replicates the SVG:
///   path  M8 22 L12 13 L16.5 19.5 L19.5 15 L25 22   (34×34 grid)
///   circle cx=25 cy=10 r=3.2
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Normalised points from the SVG (originally on a 34×34 grid)
    final points = [
      Offset(8 / 34 * w,    22 / 34 * h),
      Offset(12 / 34 * w,   13 / 34 * h),
      Offset(16.5 / 34 * w, 19.5 / 34 * h),
      Offset(19.5 / 34 * w, 15 / 34 * h),
      Offset(25 / 34 * w,   22 / 34 * h),
    ];

    // White route line
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    // Light-blue destination dot (top-right, matching SVG cx=25 cy=10)
    canvas.drawCircle(
      Offset(25 / 34 * w, 10 / 34 * h),
      3.2 / 34 * w,
      Paint()..color = const Color(0xFF64B5F6)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) => false;
}
