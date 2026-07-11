import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/create_trip_screen.dart';
import 'package:digiQ/features/driver/driver_booking_list_screen.dart';
import 'package:digiQ/features/driver/driver_verification_screen.dart';
import 'package:digiQ/features/driver/my_trips_screen.dart';
import 'package:digiQ/features/driver/payout_history_screen.dart';
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
import 'package:digiQ/models/vehicle_model.dart';
import 'package:digiQ/providers/driver_vehicle_provider.dart';
import 'package:digiQ/providers/fleet_provider.dart';
import 'package:digiQ/models/fleet_invitation_model.dart';

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
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Error loading vehicle',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(driverVehicleProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (vehicles) {
        return _buildDashboard(context, user, vehicles);
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
      BuildContext context, UserModel user, List<VehicleModel> vehicles) {
    final isVehicleApproved = vehicles.any((v) => v.isApproved);
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
            // ── FLEET INVITATIONS ─────────────────────────────────────
            _FleetInvitationBanner(ref: ref),
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
            _VehicleStatusCard(vehicles: vehicles),

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
  final List<VehicleModel> vehicles;

  const _VehicleStatusCard({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return _StatusBanner(
        text: 'No vehicle added',
        subtext: 'Add a vehicle to start accepting trips',
        color: Colors.grey,
        icon: Icons.directions_car_outlined,
      );
    }
    if (vehicles.any((v) => v.isApproved)) {
      final count = vehicles.where((v) => v.isApproved).length;
      return _StatusBanner(
        text: count == 1 ? 'Vehicle approved' : '$count vehicles approved',
        subtext: 'Your vehicle${count == 1 ? ' is' : 's are'} ready for trips',
        color: AppTheme.success,
        icon: Icons.check_circle_outline,
      );
    }
    if (vehicles.any((v) => v.isPending)) {
      return _StatusBanner(
        text: 'Vehicle under review',
        subtext: 'Usually takes a few hours',
        color: AppTheme.warning,
        icon: Icons.hourglass_top_outlined,
      );
    }
    return _StatusBanner(
      text: 'Vehicle rejected',
      subtext: 'Please resubmit your documents',
      color: AppTheme.danger,
      icon: Icons.cancel_outlined,
    );
  }
}


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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Balance row ──────────────────────────────────────────────────
          Row(
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
                  loading: () => const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Balance unavailable',
                    style: GoogleFonts.dmSans(
                        color: Colors.white70, fontSize: 13),
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

          const SizedBox(height: 16),

          // ── Action buttons ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: 'Request Payout',
                  icon: Icons.payments_outlined,
                  onTap: () => _showPayoutDialog(context, ref, balanceAsync.value?.balance ?? 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  label: 'History',
                  icon: Icons.history,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PayoutHistoryScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPayoutDialog(
      BuildContext context, WidgetRef ref, double currentBalance) async {
    final amountCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: R ${currentBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF56687A)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (ZAR)',
                prefixText: 'R ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              await _submitPayout(context, ref, amount);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayout(
      BuildContext context, WidgetRef ref, double amount) async {
    try {
      final api = ref.read(driverApiProvider);
      await api.requestWithdrawal(amount);
      ref.invalidate(driverBalanceProvider);
      ref.invalidate(payoutHistoryProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Payout request submitted — admin will process it shortly')),
      );
    } on DioException catch (e) {
      if (!context.mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Payout request failed. Please try again.';

      // Bank details missing — prompt driver to add them then retry
      if (msg.contains('Banking details not on file')) {
        final saved = await _showBankDetailsDialog(context, ref);
        if (saved == true && context.mounted) {
          await _submitPayout(context, ref, amount);
        }
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payout request failed. Please try again.')),
      );
    }
  }

  Future<bool?> _showBankDetailsDialog(
      BuildContext context, WidgetRef ref) async {
    final bankNameCtrl = TextEditingController();
    final accountNameCtrl = TextEditingController();
    final accountNumberCtrl = TextEditingController();
    final branchCodeCtrl = TextEditingController();
    String accountType = 'cheque';
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Banking Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your banking details are required before a payout can be processed.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: bankNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Bank name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: accountNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Account holder name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: accountNumberCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Account number'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: branchCodeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Branch code (optional)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey(accountType),
                    initialValue: accountType,
                    decoration:
                        const InputDecoration(labelText: 'Account type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'cheque', child: Text('Cheque')),
                      DropdownMenuItem(
                          value: 'savings', child: Text('Savings')),
                    ],
                    onChanged: (v) => setS(() => accountType = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final api = ref.read(driverApiProvider);
                  await api.updateBankDetails(
                    bankName: bankNameCtrl.text.trim(),
                    accountName: accountNameCtrl.text.trim(),
                    accountNumber: accountNumberCtrl.text.trim(),
                    branchCode: branchCodeCtrl.text.trim().isEmpty
                        ? null
                        : branchCodeCtrl.text.trim(),
                    accountType: accountType,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on DioException catch (e) {
                  final data = e.response?.data;
                  final msg = (data is Map && data['message'] != null)
                      ? data['message'].toString()
                      : 'Failed to save bank details.';
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                }
              },
              child: const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

// ── Fleet invitation banner ──────────────────────────────────────────────────

class _FleetInvitationBanner extends ConsumerWidget {
  final WidgetRef ref;
  const _FleetInvitationBanner({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(fleetInvitationsProvider);

    return invitationsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (invitations) {
        if (invitations.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            ...invitations.map(
              (inv) => _InvitationCard(invitation: inv),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  final FleetInvitation invitation;
  const _InvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fleet Invitation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${invitation.fleetOwnerName} has invited you to join their fleet.',
              style: TextStyle(
                  fontSize: 13, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onPrimaryContainer,
                      side: BorderSide(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.4)),
                    ),
                    onPressed: () async {
                      try {
                        await ref
                            .read(fleetInvitationsProvider.notifier)
                            .decline(invitation.invitationId);
                      } catch (_) {}
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(fleetInvitationsProvider.notifier)
                            .accept(invitation.invitationId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'You joined ${invitation.fleetOwnerName}\'s fleet!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
