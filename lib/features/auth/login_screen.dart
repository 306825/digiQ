import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Login (Temporary)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            ElevatedButton(
              onPressed: authState.status == AuthStatus.authenticating
                  ? null
                  : () {
                      ref.read(authProvider.notifier).login(
                            identifier: 'test_passenger',
                            password: 'test',
                          );
                    },
              child: const Text('Login as Passenger'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: authState.status == AuthStatus.authenticating
                  ? null
                  : () {
                      ref.read(authProvider.notifier).login(
                            identifier: 'test_driver',
                            password: 'test',
                          );
                    },
              child: const Text('Login as Driver'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
