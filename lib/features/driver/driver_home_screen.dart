import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/create_trip_screen.dart';
import 'package:digiQ/features/driver/driver_booking_list_screen.dart';
import 'package:digiQ/features/driver/driver_vehicle_screen.dart';
import 'package:digiQ/features/driver/driver_verification_screen.dart';
import 'package:digiQ/features/driver/my_trips_screen.dart';
import 'package:digiQ/features/shared/widgets/animated_hourglass.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/driver_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// final driverVehicleProvider = FutureProvider((ref) async {
//   final api = ref.read(driverApiProvider);
//   return api.getMyVehicle();
// });

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  //late final Future<Map<String, dynamic>?> _vehicleFuture;
  //final vehicleAsync = ref.watch(driverVehicleProvider);
  //final user = ref.watch(authProvider.select((a) => a.user));

  @override
  void initState() {
    super.initState();

    // Future.microtask(() {
    //   ref.read(driverVehicleProvider.future);
    // });
    final api = ref.read(driverApiProvider);
    //_vehicleFuture = api.getMyVehicle();
  }

  // @override
  // Widget build(BuildContext context) {
  //   //final auth = ref.watch(authProvider);
  //   //final user = auth.user;
  //   final user = ref.watch(authProvider.select((a) => a.user));

  //   if (user == null) {
  //     debugPrint('Driver home screen: User is null');
  //     return const Scaffold(
  //       body: Center(child: CircularProgressIndicator()),
  //     );
  //   }

  //   if (user.isActive == false) {
  //     debugPrint('Driver home screen: User is deactived');
  //     return Scaffold(
  //       appBar: AppBar(title: const Text('Driver Dashboard')),
  //       body: const Center(
  //         child: Text('Your account is deactivated'),
  //       ),
  //     );
  //   }

  //   //final vehicleAsync = ref.watch(driverVehicleProvider);
  //   debugPrint('Driver home screen: Just Triggered vehicle async');

  //   return vehicleAsync.when(
  //     loading: () => const Scaffold(
  //       body: Center(child: CircularProgressIndicator()),
  //     ),
  //     error: (e, _) {
  //       print("❌ VEHICLE ERROR: $e");
  //       return const Scaffold(
  //         body: Center(child: Text('Error loading vehicle')),
  //       );
  //     },
  //     data: (vehicle) {
  //       // 🚫 NO VEHICLE
  //       debugPrint('Driver home screen: No data found fore vehicles');
  //       if (vehicle == null) {
  //         return Scaffold(
  //           body: _NoVehicleView(),
  //         );
  //       }

  //       // ⏳ VEHICLE NOT APPROVED
  //       if (vehicle['status'] != 'approved') {
  //         debugPrint('Driver home screen: Vehicle not approved');
  //         return Scaffold(
  //           appBar: AppBar(title: const Text('Driver Dashboard')),
  //           body: _VehiclePendingView(status: vehicle['status']),
  //         );
  //       }
  //       debugPrint('Driver home screen: Vehicle  approved');
  //       // ✅ VEHICLE APPROVED → NORMAL APP
  //       return Scaffold(
  //         appBar: AppBar(
  //           title: const Text('Driver Dashboard'),
  //           centerTitle: true,
  //           actions: [
  //             IconButton(
  //               icon: const Icon(Icons.logout),
  //               onPressed: () async {
  //                 await ref.read(authProvider.notifier).logout();
  //                 if (!context.mounted) return;
  //                 context.go('/login');
  //               },
  //             ),
  //           ],
  //         ),
  //         body: SafeArea(
  //           child: ListView(
  //             padding: const EdgeInsets.all(16),
  //             children: [
  //               _DriverStatusCard(status: user.verificationStatus),
  //               const SizedBox(height: 12),
  //               //const _DriverBalanceCard(),
  //               const SizedBox(height: 24),

  //               /// 🚦 VERIFIED DRIVER ACTIONS
  //               if (user.isDriverVerified) ...[
  //                 _PrimaryActionButton(
  //                   label: 'Create Trip',
  //                   icon: Icons.add_circle_outline,
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => const CreateTripScreen(),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //                 const SizedBox(height: 12),
  //                 _PrimaryActionButton(
  //                   label: 'View Booking Requests',
  //                   icon: Icons.assignment,
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => const DriverBookingListScreen(),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //                 const SizedBox(height: 12),
  //                 _SecondaryActionButton(
  //                   label: 'My Trips',
  //                   icon: Icons.route,
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => const MyTripsScreen(),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],

  //               /// 🟡 NOT VERIFIED DRIVER ACTIONS
  //               if (!user.isDriverVerified) ...[
  //                 _PrimaryActionButton(
  //                   label: user.isVerificationPending
  //                       ? 'Verification Pending'
  //                       : 'Complete Driver Verification',
  //                   icon: Icons.verified_user,
  //                   disabled: user.isVerificationPending,
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (_) => const DriverVerificationScreen(),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((a) => a.user));
    //final user = ref.watch(authProvider.select((a) => a.user));
    final vehicleAsync = ref.watch(driverVehicleProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user.isActive == false) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: const Center(
          child: Text('Your account is deactivated'),
        ),
      );
    }

    return vehicleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Error loading vehicle')),
      ),
      data: (vehicle) {
        final isVehicleApproved = vehicle?['status'] == 'approved';

        if (vehicle == null) {
          return Scaffold(
            body: _NoVehicleView(
              onAddVehicle: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverVehicleScreen(),
                  ),
                );
              },
            ),
          );
        }

        if (vehicle['status'] != 'approved') {
          return _VehiclePendingView(status: vehicle['status']);
        }

// ✅ VEHICLE APPROVED → FULL DASHBOARD
        return _buildApprovedDashboard(context, user);
      },
    );
  }

  Widget _buildApprovedDashboard(BuildContext context, UserModel user) {
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

final driverVehicleProvider = FutureProvider((ref) async {
  final api = ref.read(driverApiProvider);
  return api.getMyVehicle();
});

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

// /* --------------------------------------------------------------------------
//  * Status Card
//  * -------------------------------------------------------------------------- */

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

class _VehiclePendingView extends ConsumerWidget {
  final String status;

  const _VehiclePendingView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// 🔹 STATUS CARD
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const AnimatedHourglass(),
                      const SizedBox(height: 12),
                      const Text(
                        "Vehicle Under Review",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your vehicle documents are being reviewed. This usually takes a few hours.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Status: $status",
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 STEP PROGRESS
              Column(
                children: const [
                  _StepTile("Driver Verification", true),
                  _StepTile("Vehicle Submitted", true),
                  _StepTile("Vehicle Approved", false),
                ],
              ),

              const SizedBox(height: 24),

              /// 🔹 REFRESH BUTTON
              TextButton.icon(
                onPressed: () {
                  //ref.invalidate(driverVehicleProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Status"),
              ),

              const SizedBox(height: 8),

              const Text(
                "Last updated just now",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final bool completed;

  const _StepTile(this.title, this.completed);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        completed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: completed ? Colors.green : Colors.grey,
      ),
      title: Text(title),
    );
  }
}

class _NoVehicleView extends StatelessWidget {
  final VoidCallback onAddVehicle;

  const _NoVehicleView({required this.onAddVehicle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You need to add a vehicle before driving'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAddVehicle,
            child: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}
