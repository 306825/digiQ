import 'package:digiQ/features/driver/create_trip_screen.dart';
import 'package:digiQ/features/driver/driver_booking_list_screen.dart';
import 'package:digiQ/features/driver/driver_verification_screen.dart';
import 'package:digiQ/features/driver/my_trips_screen.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/driver_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.isActive == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.block, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Your account has been deactivated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please contact support for assistance.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DriverStatusCard(status: user.verificationStatus),
            const SizedBox(height: 12),
            const _DriverBalanceCard(),
            const SizedBox(height: 24),

            /// 🚦 VERIFIED DRIVER ACTIONS
            if (user.isDriverVerified) ...[
              _PrimaryActionButton(
                label: 'Create Trip',
                icon: Icons.add_circle_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateTripScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _PrimaryActionButton(
                label: 'View Booking Requests',
                icon: Icons.assignment,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverBookingListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SecondaryActionButton(
                label: 'My Trips',
                icon: Icons.route,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyTripsScreen(),
                    ),
                  );
                },
              ),
            ],

            /// 🟡 NOT VERIFIED DRIVER ACTIONS
            if (!user.isDriverVerified) ...[
              _PrimaryActionButton(
                label: user.isVerificationPending
                    ? 'Verification Pending'
                    : 'Complete Driver Verification',
                icon: Icons.verified_user,
                disabled: user.isVerificationPending,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverVerificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Status Card
 * -------------------------------------------------------------------------- */

class _DriverStatusCard extends StatelessWidget {
  final DriverVerificationStatus status;

  const _DriverStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    late String text;
    late Color color;
    late IconData icon;

    switch (status) {
      case DriverVerificationStatus.approved:
        text = 'You are a verified driver';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case DriverVerificationStatus.pending:
        text = 'Your verification is under review';
        color = Colors.orange;
        icon = Icons.hourglass_top;
        break;
      case DriverVerificationStatus.rejected:
        text = 'Verification rejected. Please resubmit your documents.';
        color = Colors.red;
        icon = Icons.error;
        break;
      case DriverVerificationStatus.none:
        text = 'Driver verification required to accept bookings';
        color = Colors.grey;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Buttons
 * -------------------------------------------------------------------------- */

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _DriverBalanceCard extends ConsumerWidget {
  const _DriverBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(driverBalanceProvider);

    return balanceAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.red.withOpacity(0.1),
        ),
        child: const Text(
          'Failed to load balance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      data: (balance) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.blue.withOpacity(0.08),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R ${balance.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
