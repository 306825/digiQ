import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:strut/core/api/api_providers.dart';
import 'package:strut/models/admin_stats_model.dart';
import 'package:strut/theme/app.theme.dart';

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final api = ref.read(adminApiProvider);
  return api.getStats();
});

/// Platform ledger: registration, booking, trip and transaction totals.
///
/// Kept read-only on purpose — this is evidence for gateway applications, not
/// an operational screen.
class AdminOverviewTab extends ConsumerWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => _ErrorView(
        error: e,
        onRetry: () => ref.invalidate(adminStatsProvider),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MoneySection(totals: stats.transactions),
            const SizedBox(height: 20),
            _SectionHeading('Bookings'),
            _StatGrid(tiles: [
              _Stat('Confirmed', stats.bookings.confirmed,
                  icon: Icons.check_circle_outline, color: AppTheme.success),
              _Stat('Pending', stats.bookings.pending,
                  icon: Icons.hourglass_empty, color: AppTheme.warning),
              _Stat('Cancelled', stats.bookings.cancelled,
                  icon: Icons.cancel_outlined, color: AppTheme.danger),
              _Stat('All bookings', stats.bookings.total,
                  icon: Icons.receipt_long_outlined),
            ]),
            const SizedBox(height: 20),
            _SectionHeading('Trips'),
            _StatGrid(tiles: [
              _Stat('Completed', stats.trips.completed,
                  icon: Icons.flag_outlined, color: AppTheme.success),
              _Stat('Cancelled', stats.trips.cancelled,
                  icon: Icons.block, color: AppTheme.danger),
              _Stat('All trips', stats.trips.total,
                  icon: Icons.alt_route),
            ]),
            const SizedBox(height: 20),
            _SectionHeading('Registered users'),
            _StatGrid(tiles: [
              _Stat('Passengers', stats.users.passengers,
                  icon: Icons.person_outline),
              _Stat('Drivers', stats.users.drivers,
                  icon: Icons.local_taxi_outlined),
              _Stat('Verified drivers', stats.users.driversVerified,
                  icon: Icons.verified_user_outlined, color: AppTheme.success),
              _Stat('Fleet owners', stats.users.fleetOwners,
                  icon: Icons.business_outlined),
            ]),
            if (stats.generatedAt != null) ...[
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'As at ${DateFormat('d MMM yyyy, HH:mm').format(stats.generatedAt!.toLocal())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Money
 * -------------------------------------------------------------------------- */

class _MoneySection extends StatelessWidget {
  final TransactionTotals totals;
  const _MoneySection({required this.totals});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final money = NumberFormat.currency(
      symbol: totals.currency == 'ZAR' ? 'R ' : '${totals.currency} ',
      decimalDigits: 2,
    );

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
          Text(
            'Total transacted (confirmed)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            money.format(totals.confirmedAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paid directly between passenger and driver — Strut does not hold '
            'or route these funds.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MoneyStat(
                  label: 'Last 30 days',
                  value: money.format(totals.last30DaysAmount),
                  sub: '${totals.last30DaysCount} bookings',
                ),
              ),
              Expanded(
                child: _MoneyStat(
                  label: 'Incl. pending',
                  value: money.format(totals.totalAmount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyStat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _MoneyStat({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

/* --------------------------------------------------------------------------
 * Counts
 * -------------------------------------------------------------------------- */

class _SectionHeading extends StatelessWidget {
  final String text;
  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;

  _Stat(this.label, this.value, {required this.icon, this.color});
}

class _StatGrid extends StatelessWidget {
  final List<_Stat> tiles;
  const _StatGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on phones, more on wide screens.
        final columns = constraints.maxWidth > 620 ? 4 : 2;
        const gap = 12.0;
        final width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: _StatTile(stat: tile)),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = stat.color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.decimalPattern().format(stat.value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Error state
 * -------------------------------------------------------------------------- */

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  /// A 404 means the reporting endpoint has not been deployed yet, which is a
  /// different problem from a network or permission failure — say so plainly
  /// rather than showing a generic error.
  bool get _notDeployed =>
      error is DioException &&
      (error as DioException).response?.statusCode == 404;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _notDeployed ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _notDeployed
                  ? 'Reporting not available yet'
                  : 'Could not load platform totals',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _notDeployed
                  ? 'The server does not yet provide GET /admin/stats. '
                      'Totals will appear here once it is deployed.'
                  : 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
