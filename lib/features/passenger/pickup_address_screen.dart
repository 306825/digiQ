import 'dart:async';

import 'package:dio/dio.dart';
import 'package:strut/core/api/booking_api.dart';
import 'package:strut/models/route_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../shared/widgets/primary_button.dart';
import 'bank_payment_screen.dart';

const _kApiKey = 'AIzaSyBUPxGXp0U0plvCgHl_icV8e2kXuI8CX1A';

// ---------------------------------------------------------------------------
// Lightweight Places autocomplete via direct REST calls (no extra package).
// ---------------------------------------------------------------------------

class _PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;

  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

Future<List<_PlaceSuggestion>> _autocomplete(String input) async {
  if (input.length < 2) return [];
  try {
    final resp = await Dio().get(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: {
        'input': input,
        'key': _kApiKey,
        'components': 'country:za',
        'language': 'en',
      },
    );
    final predictions = resp.data['predictions'] as List? ?? [];
    return predictions.map((p) {
      final terms = p['structured_formatting'] as Map;
      return _PlaceSuggestion(
        placeId: p['place_id'] as String,
        mainText: terms['main_text'] as String? ?? '',
        secondaryText: terms['secondary_text'] as String? ?? '',
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

/// Returns {addressLine, area, lat, lng} for a given placeId.
Future<Map<String, dynamic>?> _fetchPlaceDetails(String placeId) async {
  try {
    final resp = await Dio().get(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: {
        'place_id': placeId,
        'key': _kApiKey,
        'fields': 'formatted_address,geometry,address_components',
      },
    );
    final result = resp.data['result'] as Map?;
    if (result == null) return null;

    final address = result['formatted_address'] as String? ?? '';
    final loc = result['geometry']?['location'];
    final lat = (loc?['lat'] as num?)?.toDouble();
    final lng = (loc?['lng'] as num?)?.toDouble();

    final components = result['address_components'] as List? ?? [];
    String area = '';
    for (final c in components) {
      final types = (c['types'] as List).cast<String>();
      if (types.contains('sublocality') || types.contains('locality')) {
        area = c['long_name'] as String;
        break;
      }
    }

    return {
      'addressLine': address,
      'area': area,
      'lat': lat,
      'lng': lng,
    };
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PickupAddressScreen extends ConsumerStatefulWidget {
  final Trip trip;
  final RouteDropoff selectedDropoff;

  const PickupAddressScreen({
    super.key,
    required this.trip,
    required this.selectedDropoff,
  });

  @override
  ConsumerState<PickupAddressScreen> createState() => _PickupAddressScreenState();
}

class _PickupAddressScreenState extends ConsumerState<PickupAddressScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;

  String? _selectedAddress;
  String? _selectedArea;
  double? _selectedLat;
  double? _selectedLng;

  int _seatsBooked = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedAddress = null;
      });
      return;
    }
    if (_selectedAddress != null) {
      setState(() => _selectedAddress = null);
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await _autocomplete(value.trim());
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(_PlaceSuggestion s) async {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _isSearching = true;
      _searchController.text = '${s.mainText}, ${s.secondaryText}';
    });

    final details = await _fetchPlaceDetails(s.placeId);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      if (details != null) {
        _selectedAddress = details['addressLine'] as String?;
        _selectedArea = details['area'] as String? ?? s.secondaryText;
        _selectedLat = details['lat'] as double?;
        _selectedLng = details['lng'] as double?;
        _searchController.text = _selectedAddress ?? _searchController.text;
      }
    });
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

    if (_selectedAddress == null) {
      _showSnack('Please select an address from the suggestions');
      return;
    }

    setState(() => _isSubmitting = true);

    final bookingApi = ref.read(bookingApiProvider);

    try {
      final bookingRes = await bookingApi.createBooking(
        tripId: widget.trip.id,
        seatsBooked: _seatsBooked,
        pickup: {
          'addressLine': _selectedAddress!,
          'area': _selectedArea ?? '',
          if (_selectedLat != null) 'lat': _selectedLat,
          if (_selectedLng != null) 'lng': _selectedLng,
          if (_notesController.text.trim().isNotEmpty)
            'notes': _notesController.text.trim(),
        },
        dropoffLabel: widget.selectedDropoff.label,
      );

      final bookingId = bookingRes.data['bookingId'] as String;
      final paymentReference = bookingRes.data['paymentReference'] as String? ?? '';
      final amount = (bookingRes.data['amount'] as num?)?.toDouble() ?? 0.0;
      final bankRaw = bookingRes.data['driverBankDetails'];
      final driverBankDetails = bankRaw != null
          ? Map<String, String?>.from(
              (bankRaw as Map).map((k, v) => MapEntry(k.toString(), v?.toString())))
          : null;
      final payshapId = (bankRaw as Map?)?['payshapId'] as String?;

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BankPaymentScreen(
            bookingId: bookingId,
            paymentReference: paymentReference,
            amount: amount,
            driverBankDetails: driverBankDetails,
            payshapId: payshapId,
          ),
        ),
      );

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint('❌ BOOKING ERROR: $e');
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
    final dropoff = widget.selectedDropoff;
    final total = dropoff.price * _seatsBooked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route + drop-off summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Where should the driver pick you up?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.trip.from} → ${widget.trip.to}',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                  // Selected drop-off chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer),
                            const SizedBox(width: 6),
                            Text(
                              'Drop-off: ${dropoff.label}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _seatsBooked == 1
                              ? 'R${dropoff.price.toStringAsFixed(0)}'
                              : 'R${total.toStringAsFixed(0)} ($_seatsBooked seats)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search field + suggestions
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address search
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        labelText: 'Search pickup address',
                        hintText: 'Start typing your street or suburb…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _selectedAddress != null
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),

                    // Pickup suggestions list
                    if (_suggestions.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(top: 4),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = _suggestions[i];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined,
                                  color: Colors.grey),
                              title: Text(s.mainText,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(s.secondaryText,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              onTap: () => _selectSuggestion(s),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Seat count picker
                    _SeatPicker(
                      seats: _seatsBooked,
                      maxSeats: widget.trip.seatsAvailable,
                      onChanged: (v) => setState(() => _seatsBooked = v),
                    ),

                    const SizedBox(height: 20),

                    // Notes
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes for driver (optional)',
                        hintText: 'Gate code, landmark, special instructions…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: PrimaryButton(
                  text: _isSubmitting
                      ? 'Submitting…'
                      : 'Confirm — Pay R${total.toStringAsFixed(0)}',
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

// ---------------------------------------------------------------------------
// Seat count picker widget
// ---------------------------------------------------------------------------

class _SeatPicker extends StatelessWidget {
  final int seats;
  final int maxSeats;
  final ValueChanged<int> onChanged;

  const _SeatPicker({
    required this.seats,
    required this.maxSeats,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_seat_outlined, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Number of seats',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '$maxSeats seat${maxSeats == 1 ? '' : 's'} available',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: seats > 1 ? () => onChanged(seats - 1) : null,
            color: cs.primary,
          ),
          Text(
            '$seats',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: seats < maxSeats ? () => onChanged(seats + 1) : null,
            color: cs.primary,
          ),
        ],
      ),
    );
  }
}
