import 'package:flutter/material.dart';

/// Struttech logo mark — white route path on teal background with gold dot.
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  static const _grad = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF004D40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  BoxDecoration _box(double size) => BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.50),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.10),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(painter: _RoutePainter());

    return Container(
      width: size,
      height: size,
      decoration: _box(size),
      child: Padding(
        padding: EdgeInsets.all(size * 0.09),
        child: mark,
      ),
    );
  }
}

/// Replicates the website SVG route path (34×34 grid), scaled up.
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = [
      Offset(8 / 34 * w,    22 / 34 * h),
      Offset(12 / 34 * w,   13 / 34 * h),
      Offset(16.5 / 34 * w, 19.5 / 34 * h),
      Offset(19.5 / 34 * w, 15 / 34 * h),
      Offset(25 / 34 * w,   22 / 34 * h),
    ];

    // White route line — thicker for larger display
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Gold destination dot
    canvas.drawCircle(
      Offset(25 / 34 * w, 10 / 34 * h),
      4.5 / 34 * w,
      Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) => false;
}
