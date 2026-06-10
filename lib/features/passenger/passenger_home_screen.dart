import 'package:digiQ/features/passenger/live_tracking_screen.dart';
import 'package:digiQ/features/passenger/my_bookings_screen.dart';
import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/models/route_model.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:digiQ/providers/routes_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trip_search_results_screen.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  RouteModel? _selectedRoute;
  DateTime? _date;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / '
      '${d.month.toString().padLeft(2, '0')} / '
      '${d.year}';

  // ── Verified Drivers bottom sheet ────────────────────────────────────────

  void _showVerifiedDriversSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.verified_user,
        iconColor: AppTheme.primary,
        title: 'Verified Drivers',
        items: const [
          _InfoItem(
            icon: Icons.badge_outlined,
            title: 'Identity Verified',
            body:
                'Every driver submits a government-issued ID that is reviewed before they can list trips.',
          ),
          _InfoItem(
            icon: Icons.credit_card_outlined,
            title: "Driver's Licence Checked",
            body:
                "We verify each driver's licence is valid, current, and matches the class required for passenger transport.",
          ),
          _InfoItem(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Registration',
            body:
                'The vehicle used for trips must be registered and the documents must be up to date.',
          ),
          _InfoItem(
            icon: Icons.security_outlined,
            title: 'Police Clearance',
            body:
                'Drivers provide a police clearance certificate as part of the onboarding process.',
          ),
          _InfoItem(
            icon: Icons.star_rate_outlined,
            title: 'Ongoing Reviews',
            body:
                'Passenger ratings and reports are monitored continuously. Drivers with safety concerns are suspended.',
          ),
        ],
      ),
    );
  }

  // ── Secure Payment bottom sheet ──────────────────────────────────────────

  void _showSecurePaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InfoSheet(
        icon: Icons.lock,
        iconColor: const Color(0xFF2E7D32),
        title: 'Secure Payment',
        items: const [
          _InfoItem(
            icon: Icons.lock_outline,
            title: 'Encrypted Transactions',
            body:
                'All payment data is encrypted in transit and at rest. Your card details are never stored on our servers.',
          ),
          _InfoItem(
            icon: Icons.receipt_outlined,
            title: 'Clear Pricing',
            body:
                'The price per seat is set by the driver upfront. No hidden fees or surge pricing.',
          ),
          _InfoItem(
            icon: Icons.replay_outlined,
            title: 'Refund Policy',
            body:
                'If you cancel a pending booking before the driver accepts it, your payment is refunded in full.',
          ),
          _InfoItem(
            icon: Icons.support_agent_outlined,
            title: 'Dispute Resolution',
            body:
                'If something goes wrong with a payment, raise a support ticket and our team will investigate within 24 hours.',
          ),
        ],
      ),
    );
  }

  // ── Live Tracking ────────────────────────────────────────────────────────

  void _handleLiveTracking() {
    final bookingsAsync = ref.read(passengerBookingsProvider);

    bookingsAsync.whenData((bookings) {
      // Find a booking where the driver has accepted and the trip is active
      final active = bookings.where((b) =>
          b.status == BookingStatus.approved &&
          b.passengerStatus != PassengerStatus.droppedOff &&
          b.tripId.isNotEmpty).firstOrNull;

      if (active != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(tripId: active.tripId),
          ),
        );
      } else {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _InfoSheet(
            icon: Icons.location_on,
            iconColor: AppTheme.primary,
            title: 'Live Tracking',
            items: const [
              _InfoItem(
                icon: Icons.my_location_outlined,
                title: 'Real-Time Driver Location',
                body:
                    "Once a driver accepts your booking and the trip is underway, you can see their live GPS location on the map.",
              ),
              _InfoItem(
                icon: Icons.notifications_active_outlined,
                title: 'When Is It Available?',
                body:
                    'Live tracking becomes active as soon as your booking is approved and the driver begins the trip. Check your bookings for an active trip.',
              ),
              _InfoItem(
                icon: Icons.receipt_long_outlined,
                title: 'No Active Trip',
                body:
                    "You don't have an approved trip in progress right now. Book a trip and live tracking will appear here once your driver is on the way.",
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── HERO HEADER ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0D2550), const Color(0xFF0D47A1)]
                    : [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: logo + bookings link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppLogo(size: 36, dark: true),
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MyBookingsScreen()),
                          ),
                          icon: const Icon(Icons.receipt_long,
                              color: Colors.white70, size: 18),
                          label: Text(
                            'My Bookings',
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Where are you\nheaded today?',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Find trusted drivers going your way',
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── SEARCH CARD ────────────────────────────────────────────────
          Expanded(
            child: routesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Failed to load routes')),
              data: (routes) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkCard
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Plan your trip',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),

                          // Route
                          DropdownButtonFormField<RouteModel>(
                            initialValue: _selectedRoute,
                            decoration: InputDecoration(
                              labelText: 'Route',
                              hintText: 'Select your route',
                              prefixIcon: Icon(
                                Icons.route,
                                color: isDark
                                    ? AppTheme.darkTextMuted
                                    : AppTheme.textMuted,
                              ),
                              fillColor: isDark
                                  ? AppTheme.darkBackground
                                  : AppTheme.background,
                            ),
                            items: routes
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r.label),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedRoute = v),
                          ),

                          const SizedBox(height: 14),

                          // Date picker
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Travel date',
                                prefixIcon: Icon(
                                  Icons.calendar_month_outlined,
                                  color: isDark
                                      ? AppTheme.darkTextMuted
                                      : AppTheme.textMuted,
                                ),
                                fillColor: isDark
                                    ? AppTheme.darkBackground
                                    : AppTheme.background,
                              ),
                              child: Text(
                                _date == null
                                    ? 'Select a date'
                                    : _formatDate(_date!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _date == null
                                      ? (isDark
                                          ? AppTheme.darkTextMuted
                                          : AppTheme.textMuted)
                                      : null,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Search Trips'),
                            onPressed:
                                _selectedRoute == null || _date == null
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TripSearchResultsScreen(
                                              route: _selectedRoute!,
                                              date: _date!,
                                            ),
                                          ),
                                        ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Feature chips ─────────────────────────────────────
                    Row(
                      children: [
                        _TipChip(
                          icon: Icons.verified_user_outlined,
                          label: 'Verified drivers',
                          isDark: isDark,
                          onTap: _showVerifiedDriversSheet,
                        ),
                        const SizedBox(width: 10),
                        _TipChip(
                          icon: Icons.payments_outlined,
                          label: 'Secure payment',
                          isDark: isDark,
                          onTap: _showSecurePaymentSheet,
                        ),
                        const SizedBox(width: 10),
                        _TipChip(
                          icon: Icons.location_on_outlined,
                          label: 'Live tracking',
                          isDark: isDark,
                          onTap: _handleLiveTracking,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Tip Chip
 * -------------------------------------------------------------------------- */

class _TipChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _TipChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkDivider
                    : AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkPrimary
                          : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Info Bottom Sheet
 * -------------------------------------------------------------------------- */

class _InfoSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_InfoItem> items;

  const _InfoSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Items
          ...items.map((item) => _InfoItemTile(item: item, isDark: isDark)),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String body;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _InfoItemTile extends StatelessWidget {
  final _InfoItem item;
  final bool isDark;

  const _InfoItemTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 18,
            color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.textMuted,
                    height: 1.4,
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
