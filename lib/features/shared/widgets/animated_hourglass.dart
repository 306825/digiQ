import 'package:flutter/material.dart';

class AnimatedHourglass extends StatefulWidget {
  const AnimatedHourglass({super.key});

  @override
  State<AnimatedHourglass> createState() => _AnimatedHourglassState();
}

class _AnimatedHourglassState extends State<AnimatedHourglass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.rotate(
          angle: _controller.value * 3.1416, // flip
          child: child,
        );
      },
      child: const Icon(
        Icons.hourglass_top,
        size: 48,
        color: Colors.orange,
      ),
    );
  }
}
