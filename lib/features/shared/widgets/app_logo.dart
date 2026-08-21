import 'package:flutter/material.dart';

/// Strut logo mark — uses the official brand asset.
///
/// [dark] = true  → white mark (for blue/dark backgrounds)
/// [dark] = false → full-colour mark in white rounded container
class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({super.key, this.size = 72, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final asset = dark
        ? 'assets/branding/strut/logo/strut_mark_white.png'
        : 'assets/branding/strut/logo/strut_mark_master.png';

    if (dark) {
      return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Padding(
          padding: EdgeInsets.all(size * 0.08),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
