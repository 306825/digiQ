import 'dart:async';

import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/create_trip_screen.dart';
import 'package:digiQ/features/driver/driver_booking_list_screen.dart';
import 'package:digiQ/features/driver/driver_verification_screen.dart';
import 'package:digiQ/features/driver/my_trips_screen.dart';
import 'package:digiQ/features/shared/widgets/animated_hourglass.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/driver_balance_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digiQ/core/services/tracking_service.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  late TrackingService trackingService;
  //late String tripId;

  String? activeTripId;
  Timer? trackingTimer;

  @override
  void initState() {
    super.initState();

    trackingService = TrackingService();

    //bookingId = '69f445f22a0ac8d608d9803a'; // temp test ID

    // Future.delayed(const Duration(seconds: 1), () {
    //   trackingService.joinTrip(tripId);
    // });
  }

  @override
  void dispose() {
    trackingService.disconnect();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location services disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      print('❌ Permission denied');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permission permanently denied');
      await Geolocator.openAppSettings(); // 🔥 important UX
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((a) => a.user));
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
        if (vehicle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Vehicle')),
            body: _NoVehicleView(
              onAddVehicle: () {
                context.push('/driver/vehicle');
              },
            ),
          );
        }

        return _buildDashboard(context, user, vehicle);
      },
    );
    ;
  }

  // void _startTracking(String tripId) async {
  //   if (activeTripId == tripId) return;

  //   // ✅ CHECK PERMISSION FIRST
  //   final hasPermission = await _handleLocationPermission();
  //   if (!hasPermission) {
  //     print('⛔ Cannot start tracking — no location permission');
  //     return;
  //   }

  //   activeTripId = tripId;

  //   print('🚀 Starting tracking for trip: $tripId');

  //   trackingTimer?.cancel();

  //   trackingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
  //     try {
  //       final position = await Geolocator.getCurrentPosition();

  //       trackingService.sendLocation(
  //         tripId,
  //         position.latitude,
  //         position.longitude,
  //       );
  //     } catch (e) {
  //       print('❌ Location error: $e');
  //     }
  //   });
  // }

  void _startTracking(String tripId) async {
    // trackingService.connect(
    //   'https://api.digiqueue.co.za',
    // );
    if (activeTripId == tripId) return;

    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) {
      print('⛔ Cannot start tracking — no location permission');
      return;
    }

    activeTripId = tripId;

    trackingService.connect(
      'https://api.digiqueue.co.za',
    );

    trackingService.joinTrip(tripId);

    print('🚀 Starting tracking for trip: $tripId');

    trackingTimer?.cancel();

    trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        try {
          final position = await Geolocator.getCurrentPosition();

          trackingService.sendLocation(
            tripId,
            position.latitude,
            position.longitude,
          );
        } catch (e) {
          print('❌ Location error: $e');
        }
      },
    );
  }

  void _stopTracking() {
    print('🛑 Stopping tracking');

    trackingTimer?.cancel();
    trackingTimer = null;
    activeTripId = null;
  }

  Widget _buildDashboard(
      BuildContext context, UserModel user, dynamic vehicle) {
    final isVehicleApproved = vehicle?['status'] == 'approved';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverVehicleProvider);
            ref.invalidate(authProvider);
          },
          child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // ── GREETING ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.textMuted,
                        ),
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── BALANCE CARD ──────────────────────────────────────────
            const _DriverBalanceCard(),
            const SizedBox(height: 14),

            // ── STATUS CARDS ──────────────────────────────────────────
            _DriverStatusCard(status: user.verificationStatus),
            const SizedBox(height: 10),
            _VehicleStatusCard(vehicle: vehicle),

            // ── ACTIONS ───────────────────────────────────────────────
            if (user.isDriverVerified && isVehicleApproved) ...[
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              _ActionTile(
                label: 'Create Trip',
                subtitle: 'Post a new trip for passengers',
                icon: Icons.add_road_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateTripScreen())),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                label: 'Booking Requests',
                subtitle: 'Review and manage bookings',
                icon: Icons.assignment_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DriverBookingListScreen())),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                label: 'My Trips',
                subtitle: 'View your trip history',
                icon: Icons.route_outlined,
                outlined: true,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyTripsScreen())),
              ),
            ],

            if (!user.isDriverVerified) ...[
              const SizedBox(height: 24),
              _ActionTile(
                label: user.isVerificationPending
                    ? 'Verification Pending'
                    : 'Complete Verification',
                subtitle: user.isVerificationPending
                    ? 'Your documents are under review'
                    : 'Submit your documents to start driving',
                icon: Icons.verified_user_outlined,
                disabled: user.isVerificationPending,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DriverVerificationScreen())),
              ),
            ],

            if (!isVehicleApproved) ...[
              const SizedBox(height: 10),
              _ActionTile(
                label: 'Add / Update Vehicle',
                subtitle: 'Required before accepting trips',
                icon: Icons.directions_car_outlined,
                onTap: () => context.push('/driver/vehicle'),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  final dynamic vehicle;

  const _VehicleStatusCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return _StatusBanner(
        text: 'No vehicle added',
        subtext: 'Add a vehicle to start accepting trips',
        color: Colors.grey,
        icon: Icons.directions_car_outlined,
      );
    }
    switch (vehicle['status']) {
      case 'approved':
        return _StatusBanner(
          text: 'Vehicle approved',
          subtext: 'Your vehicle is ready for trips',
          color: AppTheme.success,
          icon: Icons.check_circle_outline,
        );
      case 'pending':
        return _StatusBanner(
          text: 'Vehicle under review',
          subtext: 'Usually takes a few hours',
          color: AppTheme.warning,
          icon: Icons.hourglass_top_outlined,
        );
      case 'rejected':
        return _StatusBanner(
          text: 'Vehicle rejected',
          subtext: 'Please resubmit your documents',
          color: AppTheme.danger,
          icon: Icons.cancel_outlined,
        );
      default:
        return _StatusBanner(
          text: 'Vehicle status unknown',
          subtext: 'Please contact support',
          color: Colors.grey,
          icon: Icons.info_outline,
        );
    }
  }
}

final driverVehicleProvider = FutureProvider((ref) async {
  final api = ref.read(driverApiProvider);
  return api.getMyVehicle();
});

/* --------------------------------------------------------------------------
 * Action Tile
 * -------------------------------------------------------------------------- */

class _ActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  final bool disabled;

  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.outlined = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary =
        isDark ? AppTheme.darkPrimary : AppTheme.primary;

    return Material(
      color: outlined
          ? Colors.transparent
          : (disabled
              ? (isDark
                  ? AppTheme.darkCard
                  : AppTheme.background)
              : primary),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: disabled
                        ? (isDark ? AppTheme.darkDivider : AppTheme.divider)
                        : primary,
                    width: 1.5,
                  ),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: outlined
                      ? primary.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: outlined
                      ? (disabled
                          ? (isDark
                              ? AppTheme.darkTextMuted
                              : AppTheme.textMuted)
                          : primary)
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: outlined
                            ? (disabled
                                ? (isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.textMuted)
                                : theme.textTheme.bodyLarge?.color)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: outlined
                            ? (isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.textMuted)
                            : Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: outlined
                    ? (isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Balance Card
 * -------------------------------------------------------------------------- */

class _DriverBalanceCard extends ConsumerWidget {
  const _DriverBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(driverBalanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D2550), const Color(0xFF0D47A1)]
              : [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: balanceAsync.when(
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              error: (_, __) => Text(
                'Balance unavailable',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              data: (balance) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R ${balance.balance.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Status Banner — shared by driver status + vehicle status cards
 * -------------------------------------------------------------------------- */

class _StatusBanner extends StatelessWidget {
  final String text;
  final String subtext;
  final Color color;
  final IconData icon;

  const _StatusBanner({
    required this.text,
    required this.subtext,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtext,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color:
                        isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Driver Status Card
 * -------------------------------------------------------------------------- */

class _DriverStatusCard extends StatelessWidget {
  final DriverVerificationStatus status;

  const _DriverStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DriverVerificationStatus.approved:
        return _StatusBanner(
          text: 'Verified driver',
          subtext: 'Your account is fully verified',
          color: AppTheme.success,
          icon: Icons.verified_outlined,
        );
      case DriverVerificationStatus.pending:
        return _StatusBanner(
          text: 'Verification under review',
          subtext: 'We\'ll notify you once approved',
          color: AppTheme.warning,
          icon: Icons.hourglass_top_outlined,
        );
      case DriverVerificationStatus.rejected:
        return _StatusBanner(
          text: 'Verification rejected',
          subtext: 'Please resubmit your documents',
          color: AppTheme.danger,
          icon: Icons.cancel_outlined,
        );
      case DriverVerificationStatus.none:
        return _StatusBanner(
          text: 'Verification required',
          subtext: 'Complete verification to accept bookings',
          color: Colors.grey,
          icon: Icons.info_outline,
        );
    }
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
