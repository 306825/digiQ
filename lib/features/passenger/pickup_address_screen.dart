import 'package:digiQ/core/api/booking_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trip_model.dart';
import '../../providers/auth_provider.dart';
import '../shared/widgets/app_text_field.dart';
import '../shared/widgets/primary_button.dart';

class PickupAddressScreen extends ConsumerStatefulWidget {
  final Trip trip;

  const PickupAddressScreen({super.key, required this.trip});

  @override
  ConsumerState<PickupAddressScreen> createState() =>
      _PickupAddressScreenState();
}

class _PickupAddressScreenState extends ConsumerState<PickupAddressScreen> {
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitBooking() async {
    if (_isSubmitting) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      _showSnack('User not authenticated');
      return;
    }

    final address = _addressController.text.trim();
    final area = _areaController.text.trim();
    final notes = _notesController.text.trim();

    if (address.isEmpty || area.isEmpty) {
      _showSnack('Please enter pickup address and area');
      return;
    }

    setState(() => _isSubmitting = true);

    final api = ref.read(bookingApiProvider);

    try {
      await api.createBooking(
        tripId: widget.trip.id,
        pickup: {
          'addressLine': address,
          'area': area,
          if (notes.isNotEmpty) 'notes': notes,
        },
      );

      if (!mounted) return;

      _showSnack(
        'Booking request sent. Waiting for driver confirmation.',
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to submit booking');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              labelText: 'Street address',
              controller: _addressController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              labelText: 'Area',
              controller: _areaController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              labelText: 'Notes (optional)',
              controller: _notesController,
              multiline: true,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: _isSubmitting ? 'Submitting…' : 'Submit Booking',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitBooking,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your pickup details will be shared with the driver.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
