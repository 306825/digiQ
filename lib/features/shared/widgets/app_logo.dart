import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';

/// Struttech logo mark.
///
/// [dark] = true  → logo on transparent background (splash / blue surfaces)
/// [dark] = false → logo inside white rounded container (light surfaces)
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/branding/struttech_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (dark) {
      return SizedBox(width: size, height: size, child: logo);
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
        padding: EdgeInsets.all(size * 0.08),
        child: logo,
      ),
    );
  }
}
