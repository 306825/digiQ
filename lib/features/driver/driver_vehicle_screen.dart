import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/features/driver/driver_home_screen.dart';
import 'package:digiQ/features/driver/widgets/documents_upload_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverVehicleScreen extends ConsumerStatefulWidget {
  const DriverVehicleScreen({super.key});

  @override
  ConsumerState<DriverVehicleScreen> createState() =>
      _DriverVehicleScreenState();
}

class _DriverVehicleScreenState extends ConsumerState<DriverVehicleScreen> {
  final regCtrl = TextEditingController();
  final makeCtrl = TextEditingController();
  final modelCtrl = TextEditingController();

  String? roadworthyUrl;
  String? licenseUrl;
  String? operatingLicenseUrl;

  DateTime? roadworthyExpiry;
  DateTime? licenseExpiry;

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: regCtrl,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: makeCtrl,
              decoration: const InputDecoration(labelText: 'Make'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: modelCtrl,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 20),

            // 🔹 Upload buttons (reuse your existing uploader)
            DocumentUploadTile(
              title: "Roadworthy Certificate",
              type: "roadworthy",
              uploaded: roadworthyUrl != null,
              onUploaded: (key) {
                setState(() {
                  roadworthyUrl = key;
                });
              },
            ),

            DocumentUploadTile(
              title: "Operating License",
              type: "operating_license",
              uploaded: operatingLicenseUrl != null,
              onUploaded: (key) {
                setState(() {
                  operatingLicenseUrl = key;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (roadworthyUrl == null ||
                          operatingLicenseUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Upload required documents')),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      try {
                        await ref.read(driverApiProvider).submitVehicle(
                              registrationNumber: regCtrl.text.trim(),
                              make: makeCtrl.text.trim(),
                              model: modelCtrl.text.trim(),
                              roadworthyDocUrl: roadworthyUrl!,
                              operatingLicenseDocUrl: operatingLicenseUrl!,
                              roadworthyExpiry:
                                  DateTime.now().toIso8601String(),
                              operatingLicenseExpiry:
                                  DateTime.now().toIso8601String(),
                            );

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vehicle submitted')),
                        );

                        //ref.invalidate(
                        //    driverVehicleProvider); // ✅ force refresh
                        Navigator.pop(context, true);
                      } finally {
                        setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Submit Vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}
