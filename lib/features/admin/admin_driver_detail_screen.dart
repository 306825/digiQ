import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin_drivers_provider.dart';
import '../../../theme/app.theme.dart';

/// Returns all vehicles for a driver (list from backend)
final adminVehicleProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, driverId) async {
  final api = ref.read(adminApiProvider);
  final res = await api.dio.get('/drivers/$driverId/vehicle');
  final data = res.data;
  if (data == null || data is! List) return [];
  return (data as List).whereType<Map<String, dynamic>>().toList();
});

class AdminDriverDetailScreen extends ConsumerWidget {
  final UserModel driver;

  const AdminDriverDetailScreen({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = driver.driverProfile;
    final vehicleAsync = ref.watch(adminVehicleProvider(driver.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🔹 DRIVER INFO
          _SectionTitle('Driver Information'),
          _InfoTile('Name', driver.fullName),
          _InfoTile('Email', driver.email ?? '-'),

          const SizedBox(height: 24),

          /// 🔹 ADDRESS
          _SectionTitle('Residential Address'),
          _InfoTile('Address', profile?.residentialAddress ?? '-'),

          const SizedBox(height: 24),

          /// 🔹 BANKING
          _SectionTitle('Banking Details'),
          _InfoTile('Bank', profile?.bankName ?? '-'),
          _InfoTile('Account Name', profile?.accountName ?? '-'),
          _InfoTile('Account Number', profile?.accountNumber ?? '-'),
          _InfoTile('Branch Code', profile?.branchCode ?? '-'),
          _InfoTile('Account Type', profile?.accountType ?? '-'),

          const SizedBox(height: 24),

          /// 🔹 DRIVER DOCUMENTS
          _SectionTitle('Documents'),
          _DocumentTile('ID Document', profile?.idDocument?.fileUrl),
          _DocumentTile('Driver License', profile?.driversLicense?.fileUrl),
          _DocumentTile('Permit', profile?.permit?.fileUrl),
          _DocumentTile('PrDP', profile?.prdp?.fileUrl),
          _DocumentTile('Proof of Address', profile?.proofOfAddress?.fileUrl),
          _DocumentTile('Proof of Banking', profile?.proofOfBanking?.fileUrl),

          const SizedBox(height: 24),

          /// 🔥 VEHICLE SECTION
          _SectionTitle('Vehicle'),

          vehicleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Text('Failed to load vehicle: $e'),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const Text('No vehicle submitted');
              }
              return Column(
                children: vehicles.map((vehicle) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vehicles.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          vehicle['registrationNumber'] ?? 'Vehicle',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    _InfoTile('Registration', vehicle['registrationNumber'] ?? '-'),
                    _InfoTile('Make', vehicle['make'] ?? '-'),
                    _InfoTile('Model', vehicle['model'] ?? '-'),
                    _InfoTile('Seats', vehicle['seats']?.toString() ?? '-'),
                    _InfoTile('Status', vehicle['status'] ?? '-'),
                    _DocumentTile('Roadworthy', vehicle['roadworthyDocUrl']),
                    _DocumentTile('Operating License', vehicle['operatingLicenseDocUrl']),
                    if (vehicle['status'] == 'pending') ...[
                      const SizedBox(height: 12),
                      _VehicleActions(
                        vehicleId: vehicle['_id'],
                        driverId: driver.id,
                      ),
                    ],
                    const Divider(height: 24),
                  ],
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          /// 🔹 DRIVER ACTIONS (UNCHANGED)
          if (driver.verificationStatus == DriverVerificationStatus.pending)
            _AdminActions(driverId: driver.id),
          if (driver.verificationStatus == DriverVerificationStatus.approved)
            _StatusCard("Driver Approved", Colors.green),
          if (driver.verificationStatus == DriverVerificationStatus.rejected)
            _AdminActions(driverId: driver.id), // allow override
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final Color color;

  const _StatusCard(this.title, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.info_outline,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

/// 🔥 VEHICLE APPROVAL ACTIONS
class _VehicleActions extends ConsumerWidget {
  final String vehicleId;
  final String driverId;

  const _VehicleActions({required this.vehicleId, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(adminApiProvider);

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(Icons.check),
          label: const Text('Approve Vehicle'),
          onPressed: () async {
            try {
              await api.approveVehicle(vehicleId);

              ref.invalidate(adminDriversProvider);
              ref.invalidate(adminVehicleProvider(driverId));

              Navigator.pop(context);
            } catch (e) {
              print("❌ ERROR: $e");
            }
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(Icons.close),
          label: const Text('Reject Vehicle'),
          onPressed: () async {
            await api.rejectVehicle(vehicleId);

            ref.invalidate(adminDriversProvider);
            ref.invalidate(adminVehicleProvider);

            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _AdminActions extends ConsumerWidget {
  final String driverId;

  const _AdminActions({required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminDriversProvider.notifier);

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(Icons.check),
          label: const Text('Approve Driver'),
          onPressed: () async {
            await notifier.approve(driverId);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            minimumSize: const Size(double.infinity, 48),
          ),
          icon: const Icon(Icons.close),
          label: const Text('Reject Driver'),
          onPressed: () async {
            await notifier.reject(driverId);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final String? url;

  const _DocumentTile(this.title, this.url);

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return ListTile(
        title: Text(title),
        subtitle: const Text('Not uploaded'),
      );
    }

    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: Image.network(
                url!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
