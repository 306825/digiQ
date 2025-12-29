import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../passenger/passenger_home_screen.dart';
import '../driver/driver_home_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login (Temporary)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),

            // 🔴 TEMP: LOGIN AS PASSENGER
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).login('test', 'test');

                ref
                    .read(userProvider.notifier)
                    .setUser(
                      UserModel(
                        id: 'p1',
                        fullName: 'Test Passenger',
                        roles: ['PASSENGER'],
                        isDriverVerified: false,
                      ),
                    );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PassengerHomeScreen(),
                  ),
                );
              },
              child: const Text('Login as Passenger'),
            ),

            const SizedBox(height: 16),

            // 🔴 TEMP: LOGIN AS DRIVER
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).login('test', 'test');

                ref
                    .read(userProvider.notifier)
                    .setUser(
                      UserModel(
                        id: 'd1',
                        fullName: 'Test Driver',
                        roles: ['DRIVER'],
                        isDriverVerified: true, // IMPORTANT
                      ),
                    );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
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
