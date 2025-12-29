import 'package:digiQ/features/shared/widgets/app_text_field.dart';
import 'package:digiQ/features/shared/widgets/primary_button.dart'
    show PrimaryButton;
import 'package:digiQ/models/booking_entity.dart';
import 'package:digiQ/providers/bookings_store_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking_model.dart';

class PickupAddressScreen extends ConsumerStatefulWidget {
  final String tripId;

  const PickupAddressScreen({super.key, required this.tripId});

  @override
  ConsumerState<PickupAddressScreen> createState() =>
      _PickupAddressScreenState();
}

class _PickupAddressScreenState extends ConsumerState<PickupAddressScreen> {
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitBooking() {
    if (_addressController.text.isEmpty || _areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup address and area')),
      );
      return;
    }

    final pickup = PickupAddress(
      addressLine: _addressController.text,
      area: _areaController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    ref
        .read(bookingsStoreProvider.notifier)
        .addBooking(
          BookingEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tripId: widget.tripId,
            passengerName: 'Test Passenger',
            pickupAddress: '${pickup.addressLine}, ${pickup.area}',
            status: BookingStatus.pending,
          ),
        );

    // ✅ IMMEDIATE FEEDBACK
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking request sent. Waiting for driver confirmation.'),
      ),
    );

    // ✅ NAVIGATE BACK
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ref IS AVAILABLE HERE

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
            AppTextField(labelText: 'Area', controller: _areaController),
            AppTextField(
              labelText: 'Notes (optional)',
              controller: _notesController,
              multiline: true,
            ),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Submit Booking', onPressed: _submitBooking),
          ],
        ),
      ),
    );
  }
}
