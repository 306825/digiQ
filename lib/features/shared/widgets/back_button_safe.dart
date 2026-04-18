import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SafeBackButton extends StatelessWidget {
  final String fallbackRoute;

  const SafeBackButton({super.key, this.fallbackRoute = '/login'});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackRoute);
        }
      },
    );
  }
}
