import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:strut/features/driver/my_trips_screen.dart';
import 'package:strut/providers/driver_earnings_provider.dart';
import 'package:strut/theme/app.theme.dart';

/// Read-only cumulative earnings for the driver.
///
/// Deliberately has no payout action and does not say "available balance":
/// passengers pay the driver directly, so there is nothing for Strut to pay
/// out. See [DriverEarnings].
class DriverEarningsCard extends ConsumerWidget {
  const DriverEarningsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(driverEarningsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final money = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

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
      child: earningsAsync.when(
        loading: () => const SizedBox(
          height: 96,
          child: Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ),
        ),
        error: (_, __) => SizedBox(
          height: 96,
          child: Center(
            child: Text(
              'Earnings unavailable',
              style:
                  GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
            ),
          ),
        ),
        data: (earnings) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_up,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total earned',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        money.format(earnings.totalEarned),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Passengers pay you directly by PayShap or EFT, so this is a '
              'record of what you have earned — not a balance held by Strut.',
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Trips completed',
                    value: NumberFormat.decimalPattern()
                        .format(earnings.tripsCompleted),
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Seats sold',
                    value: NumberFormat.decimalPattern()
                        .format(earnings.seatsSold),
                  ),
                ),
                _WhiteTextButton(
                  label: 'My trips',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTripsScreen()),
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WhiteTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WhiteTextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
