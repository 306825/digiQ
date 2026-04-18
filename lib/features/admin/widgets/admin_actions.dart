import 'package:digiQ/features/admin/admin_drivers_screen.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
