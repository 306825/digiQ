// import 'package:digiQ/core/api/api_providers.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../models/user_model.dart';
// import '../../../providers/admin_drivers_provider.dart';
// import '../../../theme/app.theme.dart';

// final adminVehicleProvider =
//     FutureProvider.family<Map<String, dynamic>?, String>((ref, driverId) async {
//   final api = ref.read(adminApiProvider);
//   final res = await api.dio
//       .get('/drivers/$driverId/vehicle'); // we’ll fix endpoint next
//   final adminVehicleProvider =
//       FutureProvider.family<Map<String, dynamic>?, String>(
//           (ref, driverId) async {
//     final api = ref.read(adminApiProvider);
//     final res = await api.dio.get('/drivers/$driverId/vehicle');

//     final data = res.data;

//     if (data == null || data == '') return null;
//     if (data is Map<String, dynamic>) return data;

//     return null;
//   });
// });

// class AdminDriverDetailScreen extends ConsumerWidget {
//   final UserModel driver;

//   const AdminDriverDetailScreen({
//     super.key,
//     required this.driver,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final profile = driver.driverProfile;

//     debugPrint('PROFILE: ${profile}');
//     debugPrint('ID DOC: ${profile?.idDocument?.fileUrl}');

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Driver Review'),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _SectionTitle('Driver Information'),
//           _InfoTile('Name', driver.fullName),
//           _InfoTile('Email', driver.email ?? '-'),
//           const SizedBox(height: 24),
//           _SectionTitle('Residential Address'),
//           _InfoTile('Address', profile?.residentialAddress ?? '-'),
//           const SizedBox(height: 24),
//           _SectionTitle('Banking Details'),
//           _InfoTile('Bank', profile?.bankName ?? '-'),
//           _InfoTile('Account Name', profile?.accountName ?? '-'),
//           _InfoTile('Account Number', profile?.accountNumber ?? '-'),
//           _InfoTile('Branch Code', profile?.branchCode ?? '-'),
//           _InfoTile('Account Type', profile?.accountType ?? '-'),
//           const SizedBox(height: 24),
//           _SectionTitle('Documents'),
//           _DocumentTile('ID Document', profile?.idDocument?.fileUrl),
//           _DocumentTile('Driver License', profile?.driversLicense?.fileUrl),
//           _DocumentTile('Permit', profile?.permit?.fileUrl),
//           _DocumentTile('PrDP', profile?.prdp?.fileUrl),
//           _DocumentTile('Proof of Address', profile?.proofOfAddress?.fileUrl),
//           _DocumentTile('Proof of Banking', profile?.proofOfBanking?.fileUrl),
//           const SizedBox(height: 32),
//           _AdminActions(driverId: driver.id),
//         ],
//       ),
//     );
//   }
// }

// class _SectionTitle extends StatelessWidget {
//   final String text;

//   const _SectionTitle(this.text);

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//   }
// }

// class _InfoTile extends StatelessWidget {
//   final String label;
//   final String value;

//   const _InfoTile(this.label, this.value);

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(label),
//       subtitle: Text(value),
//     );
//   }
// }

// class _AdminActions extends ConsumerWidget {
//   final String driverId;

//   const _AdminActions({required this.driverId});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final notifier = ref.read(adminDriversProvider.notifier);

//     return Column(
//       children: [
//         ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.success,
//             minimumSize: const Size(double.infinity, 48),
//           ),
//           icon: const Icon(Icons.check),
//           label: const Text('Approve Driver'),
//           onPressed: () async {
//             await notifier.approve(driverId);
//             Navigator.pop(context);
//           },
//         ),
//         const SizedBox(height: 12),
//         ElevatedButton.icon(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppTheme.danger,
//             minimumSize: const Size(double.infinity, 48),
//           ),
//           icon: const Icon(Icons.close),
//           label: const Text('Reject Driver'),
//           onPressed: () async {
//             await notifier.reject(driverId);
//             Navigator.pop(context);
//           },
//         ),
//       ],
//     );
//   }
// }

// class _DocumentTile extends StatelessWidget {
//   final String title;
//   final String? url;

//   const _DocumentTile(this.title, this.url);

//   @override
//   Widget build(BuildContext context) {
//     if (url == null) {
//       return ListTile(
//         title: Text(title),
//         subtitle: const Text('Not uploaded'),
//       );
//     }

//     return ListTile(
//       title: Text(title),
//       trailing: const Icon(Icons.open_in_new),
//       onTap: () {
//         showDialog(
//           context: context,
//           builder: (_) => Dialog(
//             child: InteractiveViewer(
//                 child: Image.network(
//               url!,
//               fit: BoxFit.contain,
//             )),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin_drivers_provider.dart';
import '../../../theme/app.theme.dart';

/// 🔥 VEHICLE PROVIDER (SAFE PARSING)
final adminVehicleProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, driverId) async {
  final api = ref.read(adminApiProvider);
  final res = await api.dio.get('/drivers/$driverId/vehicle');

  final data = res.data;

  if (data == null || data == '') return null;
  if (data is Map<String, dynamic>) return data;

  return null;
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
            data: (vehicle) {
              if (vehicle == null) {
                return const Text('No vehicle submitted');
              }

              return Column(
                children: [
                  _InfoTile(
                      'Registration', vehicle['registrationNumber'] ?? '-'),
                  _InfoTile('Make', vehicle['make'] ?? '-'),
                  _InfoTile('Model', vehicle['model'] ?? '-'),
                  _InfoTile('Status', vehicle['status'] ?? '-'),
                  _DocumentTile('Roadworthy', vehicle['roadworthyDocUrl']),
                  _DocumentTile(
                      'Operating License', vehicle['operatingLicenseDocUrl']),
                  const SizedBox(height: 16),
                  if (vehicle['status'] == 'pending')
                    _VehicleActions(vehicleId: vehicle['_id']),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          /// 🔹 DRIVER ACTIONS (UNCHANGED)
          _AdminActions(driverId: driver.id),
        ],
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

  const _VehicleActions({required this.vehicleId});

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
            await api.approveVehicle(vehicleId);

            ref.invalidate(adminDriversProvider);
            ref.invalidate(adminVehicleProvider);

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
