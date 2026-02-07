import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const AppLogo({
    super.key,
    this.size = 72,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      dark ? 'assets/branding/logo_q_white.png' : 'assets/branding/logo_q.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
