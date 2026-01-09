import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/driver_trips_provider.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final seatsCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  DateTime? date;

  bool submitting = false;

  Future<void> submit() async {
    if (date == null) return;

    setState(() => submitting = true);

    try {
      await ref.read(tripsApiProvider).createTrip(
            from: fromCtrl.text,
            to: toCtrl.text,
            date: date!,
            seatsTotal: int.parse(seatsCtrl.text),
            price: double.parse(priceCtrl.text),
          );

      ref.invalidate(driverTripsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create trip: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: fromCtrl,
                decoration: const InputDecoration(labelText: 'From')),
            TextField(
                controller: toCtrl,
                decoration: const InputDecoration(labelText: 'To')),
            TextField(
                controller: seatsCtrl,
                decoration: const InputDecoration(labelText: 'Seats'),
                keyboardType: TextInputType.number),
            TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: submitting ? null : submit,
              child: const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
