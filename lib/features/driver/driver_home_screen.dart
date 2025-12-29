import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/user_provider.dart';
import 'driver_booking_list_screen.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? const Center(child: Text('User not loaded'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DriverStatusCard(isVerified: user.isDriverVerified),
                  const SizedBox(height: 24),

                  // 🔴 ENTRY POINT TO BOOKING REQUESTS
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: user.isDriverVerified
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DriverBookingListScreen(),
                                ),
                              );
                            }
                          : null,
                      child: const Text('View Booking Requests'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DriverStatusCard extends StatelessWidget {
  final bool isVerified;

  const _DriverStatusCard({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isVerified ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.info,
              color: isVerified ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isVerified
                    ? 'You are a verified driver'
                    : 'Your driver verification is pending',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
