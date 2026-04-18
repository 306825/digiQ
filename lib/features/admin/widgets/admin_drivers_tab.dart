import 'package:digiQ/features/admin/admin_driver_detail_screen.dart';
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

        final pending = drivers
            .where(
                (d) => d.verificationStatus == DriverVerificationStatus.pending)
            .toList();

        final approved = drivers
            .where((d) =>
                d.verificationStatus == DriverVerificationStatus.approved)
            .toList();

        final others = drivers
            .where((d) =>
                d.verificationStatus == DriverVerificationStatus.none ||
                d.verificationStatus == DriverVerificationStatus.rejected)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(adminDriversProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DriverSection(
                title: 'Pending Verification',
                drivers: pending,
              ),
              const SizedBox(height: 24),
              _DriverSection(
                title: 'Active Drivers',
                drivers: approved,
              ),
              const SizedBox(height: 24),
              _DriverSection(
                title: 'Other Drivers',
                drivers: others,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DriverSection extends StatelessWidget {
  final String title;
  final List<UserModel> drivers;

  const _DriverSection({
    required this.title,
    required this.drivers,
  });

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...drivers.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DriverCard(driver: d),
            )),
      ],
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

    final isVerified =
        driver.verificationStatus == DriverVerificationStatus.approved;
    final hasApprovedVehicle =
        driver.vehicleStatus == VehicleVerificationStatus.approved;

    final canOperate = isActive && isVerified && hasApprovedVehicle;

    String statusMessage() {
      if (!isVerified) return 'Driver not verified';
      if (driver.vehicleStatus != VehicleVerificationStatus.approved) {
        return 'Vehicle not approved';
      }
      if (!isActive) return 'Driver inactive';
      return 'Driver can operate';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDriverDetailScreen(driver: driver),
          ),
        );
      },
      child: Container(
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
                if (driver.vehicleStatus != VehicleVerificationStatus.none)
                  _StatusPill(
                    label: _vehicleLabel(driver.vehicleStatus),
                    color: _vehicleColor(driver.vehicleStatus),
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
                      canOperate ? 'Driver Active' : 'Driver Cannot Operate',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      canOperate
                          ? 'Driver can create and accept trips'
                          : statusMessage(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDark,
                      ),
                    )
                  ],
                ),
                Switch.adaptive(
                  value: canOperate,
                  activeColor: AppTheme.success,
                  onChanged: driver.verificationStatus !=
                          DriverVerificationStatus.approved
                      ? null
                      : (value) async {
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

  String _vehicleLabel(VehicleVerificationStatus status) {
    switch (status) {
      case VehicleVerificationStatus.approved:
        return 'Vehicle Approved';
      case VehicleVerificationStatus.pending:
        return 'Vehicle Pending';
      case VehicleVerificationStatus.rejected:
        return 'Vehicle Rejected';
      case VehicleVerificationStatus.none:
        return 'No Vehicle';
    }
  }

  Color _vehicleColor(VehicleVerificationStatus status) {
    switch (status) {
      case VehicleVerificationStatus.approved:
        return AppTheme.success;
      case VehicleVerificationStatus.pending:
        return AppTheme.warning;
      case VehicleVerificationStatus.rejected:
        return AppTheme.danger;
      case VehicleVerificationStatus.none:
        return AppTheme.textMuted;
    }
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
