import 'package:digiQ/features/shared/widgets/user_avatar.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/admin_drivers_provider.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDriversTab extends ConsumerWidget {
  const AdminDriversTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(adminDriversProvider);

    return driversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _ErrorState(),
      data: (drivers) {
        if (drivers.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(adminDriversProvider.notifier).refresh();
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              return DriverCard(driver: drivers[index]);
            },
          ),
        );
      },
    );
  }
}

class DriverCard extends ConsumerWidget {
  final UserModel driver;

  const DriverCard({required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminDriversProvider.notifier);

    final isActive = driver.isActive ?? true;
    //final isVerified = driver.isDriverVerified;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textMuted),
        color: AppTheme.surface,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────
          Row(
            children: [
              UserAvatar(
                displayName: driver.fullName,
                imageUrl: driver.profileImageUrl,
                size: 44, // radius 22 × 2
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  driver.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ActiveDot(isActive: isActive),
            ],
          ),

          const SizedBox(height: 12),

          // ── Status row ───────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                label: isActive ? 'Active' : 'Inactive',
                color: isActive ? AppTheme.success : AppTheme.danger,
              ),
              _StatusPill(
                label: _verificationLabel(driver.verificationStatus),
                color: _verificationColor(driver.verificationStatus),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Action ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Driver Active' : 'Driver Deactivated',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'Driver can create and accept trips'
                        : 'Driver is blocked from operating',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: isActive,
                activeColor: AppTheme.success,
                onChanged: (value) async {
                  // ⚠️ Confirm before deactivation
                  if (!value) {
                    final confirmed = await _confirmDeactivate(context);
                    if (!confirmed) return;
                  }

                  if (value) {
                    await notifier.activate(driver.id);
                  } else {
                    await notifier.deactivate(driver.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeactivate(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Deactivate Driver'),
            content: const Text(
              'This driver will no longer be able to create or accept trips. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Deactivate'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _verificationLabel(DriverVerificationStatus status) {
    switch (status) {
      case DriverVerificationStatus.approved:
        return 'Verified';
      case DriverVerificationStatus.pending:
        return 'Pending verification';
      case DriverVerificationStatus.rejected:
        return 'Rejected';
      case DriverVerificationStatus.none:
        return 'Not verified';
    }

    //return 'Unknown';
  }

  Color _verificationColor(DriverVerificationStatus status) {
    switch (status) {
      case DriverVerificationStatus.approved:
        return AppTheme.success;
      case DriverVerificationStatus.pending:
        return AppTheme.warning;
      case DriverVerificationStatus.rejected:
        return AppTheme.danger;
      case DriverVerificationStatus.none:
        return AppTheme.textMuted;
    }

    //return AppTheme.textMuted;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  final bool isActive;

  const _ActiveDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppTheme.success : AppTheme.danger,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_user, size: 56, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'No drivers found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no drivers in the system yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 56, color: AppTheme.danger),
            SizedBox(height: 16),
            Text(
              'Failed to load drivers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
