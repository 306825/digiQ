import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/core/api/booking_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../shared/widgets/app_text_field.dart';
import '../shared/widgets/primary_button.dart';
import 'payfast_webview_screen.dart'; // <-- IMPORTANT

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

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

    final address = _addressController.text.trim();
    final area = _areaController.text.trim();
    final notes = _notesController.text.trim();

    if (address.isEmpty || area.isEmpty) {
      _showSnack('Please enter pickup address and area');
      return;
    }

    setState(() => _isSubmitting = true);

    final bookingApi = ref.read(bookingApiProvider);
    final paymentsApi = ref.read(paymentsApiProvider);

    try {
      debugPrint('🔥 SUBMIT BOOKING PRESSED');

      // 1️⃣ Create booking first
      final bookingRes = await bookingApi.createBooking(
        tripId: widget.trip.id,
        pickup: {
          'addressLine': address,
          'area': area,
          if (notes.isNotEmpty) 'notes': notes,
        },
      );

      final bookingId = bookingRes.data['bookingId'] as String;
      debugPrint('✅ BOOKING CREATED: $bookingId');

      // 2️⃣ Ask backend to prepare PayFast payment
      debugPrint('🔥 ABOUT TO CALL PAYFAST INITIATE');

      final paymentInit = await paymentsApi.initiatePayfast(
        bookingId: bookingId,
      );

      final processUrl = paymentInit['processUrl'] as String;
      final payload = Map<String, String>.from(paymentInit['payload'] as Map);

      debugPrint('✅ PAYFAST INIT OK: $processUrl');

      // 3️⃣ OPEN IN OUR OWN WEBVIEW (FIXES YOUR 404)
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayfastWebViewScreen(
            processUrl: processUrl,
            payload: payload,
          ),
        ),
      );

      // 4️⃣ Handle result (UI only — backend is authoritative)
      if (!mounted) return;

      if (paid == true) {
        _showSnack('Payment initiated. Waiting for confirmation from PayFast.');
      } else {
        _showSnack('Payment cancelled.');
      }

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint('❌ PAYMENT INIT ERROR: $e');
      if (!mounted) return;
      _showSnack('Failed to initiate payment');
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
      appBar: AppBar(
        title: const Text('Pickup Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where should the driver pick you up?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.trip.from} → ${widget.trip.to}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            AppTextField(
                              labelText: 'Street address',
                              controller: _addressController,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              labelText: 'Area / Suburb',
                              controller: _areaController,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              labelText: 'Notes (optional)',
                              controller: _notesController,
                              multiline: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: PrimaryButton(
                  text: _isSubmitting ? 'Submitting…' : 'Confirm Pickup',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitBooking,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
