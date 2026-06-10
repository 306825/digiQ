import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/models/booking_status_ui.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return _formatDate(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(passengerBookingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── GRADIENT HEADER ───────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'My Bookings',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(error: e.toString()),
              data: (bookings) {
                if (bookings.isEmpty) return const _EmptyState();

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(passengerBookingsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final booking = bookings[index];
                      return GestureDetector(
                        onTap: () => context.push('/booking/${booking.id}'),
                        child: _BookingCard(
                          booking: booking,
                          createdLabel: _formatDate(booking.createdAt),
                          updatedLabel: _formatRelative(booking.updatedAt),
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Booking Card
 * -------------------------------------------------------------------------- */

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final String createdLabel;
  final String updatedLabel;
  final bool isDark;

  const _BookingCard({
    required this.booking,
    required this.createdLabel,
    required this.updatedLabel,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = booking.status;
    final accentColor = status.color;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.divider,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Coloured left accent ─────────────────────────────────
              Container(width: 4, color: accentColor),

              // ── Content ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: pickup + chevron
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.location_on,
                              size: 17,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.pickup.addressLine,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.textDark,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.pickup.area,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.darkTextMuted
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.textMuted,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: isDark ? AppTheme.darkDivider : AppTheme.divider,
                      ),
                      const SizedBox(height: 12),

                      // Bottom row: status chip + date + payment
                      Row(
                        children: [
                          _StatusChip(status: status),
                          const SizedBox(width: 8),
                          _PaymentBadge(
                            paymentStatus: booking.paymentStatus,
                            isDark: isDark,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            createdLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextMuted
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),

                      // Cancel button — only for pending
                      if (status == BookingStatus.pending) ...[
                        const SizedBox(height: 12),
                        _CancelButton(
                          bookingId: booking.id,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Status Chip
 * -------------------------------------------------------------------------- */

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  IconData get _icon {
    switch (status) {
      case BookingStatus.pending:
        return Icons.hourglass_top_rounded;
      case BookingStatus.approved:
        return Icons.check_circle_outline;
      case BookingStatus.rejected:
        return Icons.cancel_outlined;
      case BookingStatus.cancelled:
        return Icons.remove_circle_outline;
      case BookingStatus.awaitingPayment:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.dmSans(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Payment Badge
 * -------------------------------------------------------------------------- */

class _PaymentBadge extends StatelessWidget {
  final PaymentStatus paymentStatus;
  final bool isDark;

  const _PaymentBadge({required this.paymentStatus, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (paymentStatus == PaymentStatus.pending) return const SizedBox.shrink();

    final (label, color) = switch (paymentStatus) {
      PaymentStatus.paid => ('Paid', AppTheme.success),
      PaymentStatus.refunded => ('Refunded', AppTheme.warning),
      PaymentStatus.pending => ('', Colors.transparent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Cancel Button
 * -------------------------------------------------------------------------- */

class _CancelButton extends ConsumerWidget {
  final String bookingId;
  final bool isDark;

  const _CancelButton({required this.bookingId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(passengerBookingsProvider.notifier);
    final isProcessing = notifier.isProcessing(bookingId);

    if (isProcessing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.danger,
          side: BorderSide(
            color: AppTheme.danger.withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        icon: const Icon(Icons.close, size: 15),
        label: const Text('Cancel Booking'),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Cancel booking?',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'This booking has not been accepted yet. Are you sure you want to cancel it?',
                style: GoogleFonts.dmSans(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep booking'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, cancel'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;
          await notifier.cancel(bookingId);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Booking cancelled',
                  style: GoogleFonts.dmSans(),
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Empty State
 * -------------------------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 38,
                color: isDark ? AppTheme.darkPrimary : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No bookings yet',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a trip from the home screen\nand your rides will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Error State
 * -------------------------------------------------------------------------- */

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 38,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load bookings',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and pull down to retry.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
