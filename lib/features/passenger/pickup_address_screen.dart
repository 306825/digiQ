import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trip_model.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_store_provider.dart';
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

    final pickup = PickupAddress(
      addressLine: address,
      area: area,
      notes: notes.isEmpty ? null : notes,
    );

    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: widget.trip.id,
      passengerName: user.fullName,
      pickup: pickup,
      status: BookingStatus.pending,
    );

    // Persist locally (API later)
    ref.read(bookingsStoreProvider.notifier).addBooking(booking);

    if (!mounted) return;

    _showSnack(
      'Booking request sent. Waiting for driver confirmation.',
    );

    // Give user feedback before navigation
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
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
