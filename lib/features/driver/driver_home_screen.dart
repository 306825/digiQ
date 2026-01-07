import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/bookings_store_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'driver_booking_list_screen.dart';
import 'driver_verification_screen.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DriverStatusCard(isVerified: user.isDriverVerified),
                  const SizedBox(height: 24),

                  // 🔴 VERIFIED DRIVER: VIEW BOOKINGS
                  if (user.isDriverVerified)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverBookingListScreen(),
                            ),
                          );
                        },
                        child: const Text('View Booking Requests'),
                      ),
                    ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(bookingsStoreProvider.notifier).addBooking(
                                Booking(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  tripId: 'trip_1',
                                  passengerName: 'Debug Passenger',
                                  pickup: const PickupAddress(
                                    addressLine: '123 Main Street',
                                    area: 'Sandton',
                                  ),
                                  status: BookingStatus.pending,
                                ),
                              );
                        },
                        child: const Text('🐞 Add Debug Booking'),
                      ),
                    ),
                  ],

                  // 🟡 UNVERIFIED DRIVER: COMPLETE VERIFICATION
                  if (!user.isDriverVerified)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DriverVerificationScreen(),
                            ),
                          );
                        },
                        child: const Text('Complete Driver Verification'),
                      ),
                    ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('DEBUG: Logout (Clear Local Auth)'),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
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
