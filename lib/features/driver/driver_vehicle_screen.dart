import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/widgets/documents_upload_tile.dart';
import 'package:digiQ/models/vehicle_model.dart';
import 'package:digiQ/providers/driver_vehicle_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Vehicle list screen
// ---------------------------------------------------------------------------

class DriverVehicleScreen extends ConsumerWidget {
  const DriverVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(driverVehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        centerTitle: true,
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load vehicles')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_outlined,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No vehicles yet',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Add a vehicle to start creating trips.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                    onPressed: () => _openAddVehicle(context, ref),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...vehicles.map((v) => _VehicleCard(vehicle: v)),
              const SizedBox(height: 16),
              if (vehicles.length < 5)
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Vehicle'),
                  onPressed: () => _openAddVehicle(context, ref),
                )
              else
                const Center(
                  child: Text(
                    'Maximum of 5 vehicles reached',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAddVehicle(BuildContext context, WidgetRef ref) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _AddVehicleScreen()),
    );
    if (added == true) ref.invalidate(driverVehicleProvider);
  }
}

// ---------------------------------------------------------------------------
// Vehicle card
// ---------------------------------------------------------------------------

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (vehicle.status) {
      'approved' => (Colors.green, Icons.check_circle_outline, 'Approved'),
      'rejected' => (Colors.red, Icons.cancel_outlined, 'Rejected'),
      _ => (Colors.orange, Icons.hourglass_empty_outlined, 'Under Review'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.directions_car, size: 36, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.registrationNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (vehicle.make != null || vehicle.model != null)
                    Text(
                      [
                        if (vehicle.year != null) vehicle.year.toString(),
                        if (vehicle.make != null) vehicle.make!,
                        if (vehicle.model != null) vehicle.model!,
                      ].join(' '),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.seats} seat${vehicle.seats == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add vehicle form
// ---------------------------------------------------------------------------

class _AddVehicleScreen extends ConsumerStatefulWidget {
  const _AddVehicleScreen();

  @override
  ConsumerState<_AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<_AddVehicleScreen> {
  final regCtrl = TextEditingController();
  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final seatsCtrl = TextEditingController();

  String? roadworthyUrl;
  String? operatingLicenseUrl;
  bool loading = false;

  @override
  void dispose() {
    regCtrl.dispose();
    makeCtrl.dispose();
    modelCtrl.dispose();
    seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (regCtrl.text.trim().isEmpty) {
      _snack('Please enter a registration number');
      return;
    }
    final seats = int.tryParse(seatsCtrl.text.trim());
    if (seats == null || seats < 1) {
      _snack('Please enter the number of seats');
      return;
    }
    if (roadworthyUrl == null || operatingLicenseUrl == null) {
      _snack('Please upload the required documents');
      return;
    }

    setState(() => loading = true);
    try {
      await ref.read(driverApiProvider).submitVehicle(
            registrationNumber: regCtrl.text.trim(),
            make: makeCtrl.text.trim().isEmpty ? null : makeCtrl.text.trim(),
            model:
                modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
            seats: seats,
            roadworthyDocUrl: roadworthyUrl!,
            operatingLicenseDocUrl: operatingLicenseUrl!,
            roadworthyExpiry: DateTime.now().toIso8601String(),
            operatingLicenseExpiry: DateTime.now().toIso8601String(),
          );

      if (!mounted) return;
      _snack('Vehicle submitted for review');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: regCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration Number *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: makeCtrl,
              decoration: const InputDecoration(
                labelText: 'Make (e.g. Toyota)',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: modelCtrl,
              decoration: const InputDecoration(
                labelText: 'Model (e.g. Quantum)',
                prefixIcon: Icon(Icons.car_repair_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: seatsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Number of seats *',
                prefixIcon: Icon(Icons.event_seat_outlined),
                hintText: 'e.g. 14',
              ),
            ),
            const SizedBox(height: 20),
            DocumentUploadTile(
              title: 'Roadworthy Certificate *',
              type: 'roadworthy',
              uploaded: roadworthyUrl != null,
              onUploaded: (key) => setState(() => roadworthyUrl = key),
            ),
            DocumentUploadTile(
              title: 'Operating License *',
              type: 'operating_license',
              uploaded: operatingLicenseUrl != null,
              onUploaded: (key) => setState(() => operatingLicenseUrl = key),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
