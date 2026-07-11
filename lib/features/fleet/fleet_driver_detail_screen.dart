import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/fleet_member_model.dart';
import '../../providers/fleet_provider.dart';

class FleetDriverDetailScreen extends ConsumerWidget {
  final FleetMember member;

  const FleetDriverDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(member.driverName),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person_remove, color: Colors.red),
            label: const Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () => _confirmRemove(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile header ──────────────────────────────────────────────
          _Section(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  backgroundColor: cs.primaryContainer,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.driverName.isNotEmpty
                              ? member.driverName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 28, color: cs.onPrimaryContainer),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.driverName,
                          style: theme.textTheme.titleMedium),
                      if (member.phoneNumber != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(member.phoneNumber!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      _StatusChip(status: member.verificationStatus),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Earnings ────────────────────────────────────────────────────
          Text('Earnings', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _EarningsCard(
                  label: 'Balance',
                  amount: member.earnings.balance,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EarningsCard(
                  label: 'Total Earned',
                  amount: member.earnings.totalEarned,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EarningsCard(
                  label: 'Paid Out',
                  amount: member.earnings.totalPaidOut,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Vehicles ────────────────────────────────────────────────────
          Text('Vehicles (${member.vehicles.length})',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (member.vehicles.isEmpty)
            _empty('No vehicles on file')
          else
            ...member.vehicles.map((v) => _VehicleTile(vehicle: v)),

          const SizedBox(height: 20),

          // ── Recent trips ────────────────────────────────────────────────
          Text('Recent Trips (${member.recentTrips.length})',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (member.recentTrips.isEmpty)
            _empty('No trips yet')
          else
            ...member.recentTrips.map((t) => _TripTile(trip: t)),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      );

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from fleet?'),
        content: Text(
            '${member.driverName} will be removed from your fleet. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(fleetMembersProvider.notifier).removeMember(member.driverId);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final Widget child;
  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'approved'
        ? Colors.green
        : status == 'pending'
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final double amount;
  final bool highlight;

  const _EarningsCard({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'R${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: highlight ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: highlight
                  ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                  : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final FleetVehicle vehicle;
  const _VehicleTile({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final approved = vehicle.status == 'approved';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.directions_car,
            color: approved ? cs.primary : cs.onSurfaceVariant),
        title: Text(vehicle.displayName),
        subtitle: Text('${vehicle.seats} seats'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (approved ? Colors.green : Colors.orange)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            vehicle.status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: approved ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final FleetRecentTrip trip;
  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final date = trip.date.toLocal();
    final dateStr =
        '${date.day}/${date.month}/${date.year}';

    final statusColor = trip.status == 'completed'
        ? Colors.green
        : trip.status == 'active'
            ? cs.primary
            : trip.status == 'cancelled'
                ? Colors.red
                : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${trip.fromLabel} → ${trip.toLabel}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('R${trip.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  trip.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
