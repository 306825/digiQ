import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/core/api/booking_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../shared/widgets/primary_button.dart';
import 'payfast_webview_screen.dart';

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

    // Extract suburb/city from address_components
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

  const PickupAddressScreen({super.key, required this.trip});

  @override
  ConsumerState<PickupAddressScreen> createState() =>
      _PickupAddressScreenState();
}

class _PickupAddressScreenState extends ConsumerState<PickupAddressScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _dropoffSearchController = TextEditingController();

  List<_PlaceSuggestion> _suggestions = [];
  List<_PlaceSuggestion> _dropoffSuggestions = [];
  Timer? _debounce;
  Timer? _dropoffDebounce;
  bool _isSearching = false;
  bool _isDropoffSearching = false;

  // Confirmed pickup selection
  String? _selectedAddress;
  String? _selectedArea;
  double? _selectedLat;
  double? _selectedLng;

  // Confirmed dropoff selection
  String? _selectedDropoffAddress;
  String? _selectedDropoffArea;
  double? _selectedDropoffLat;
  double? _selectedDropoffLng;

  int _seatsBooked = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _dropoffDebounce?.cancel();
    _searchController.dispose();
    _notesController.dispose();
    _dropoffSearchController.dispose();
    super.dispose();
  }

  void _onDropoffSearchChanged(String value) {
    _dropoffDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _dropoffSuggestions = [];
        _selectedDropoffAddress = null;
      });
      return;
    }
    if (_selectedDropoffAddress != null) {
      setState(() => _selectedDropoffAddress = null);
    }
    _dropoffDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isDropoffSearching = true);
      final results = await _autocomplete(value.trim());
      if (mounted) {
        setState(() {
          _dropoffSuggestions = results;
          _isDropoffSearching = false;
        });
      }
    });
  }

  Future<void> _selectDropoffSuggestion(_PlaceSuggestion s) async {
    _dropoffDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _dropoffSuggestions = [];
      _isDropoffSearching = true;
      _dropoffSearchController.text = '${s.mainText}, ${s.secondaryText}';
    });

    final details = await _fetchPlaceDetails(s.placeId);
    if (!mounted) return;
    setState(() {
      _isDropoffSearching = false;
      if (details != null) {
        _selectedDropoffAddress = details['addressLine'] as String?;
        _selectedDropoffArea = details['area'] as String? ?? s.secondaryText;
        _selectedDropoffLat = details['lat'] as double?;
        _selectedDropoffLng = details['lng'] as double?;
        _dropoffSearchController.text =
            _selectedDropoffAddress ?? _dropoffSearchController.text;
      }
    });
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
    // Clear confirmed selection when user types again
    if (_selectedAddress != null) {
      setState(() => _selectedAddress = null);
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await _autocomplete(value.trim());
      if (mounted) setState(() {
        _suggestions = results;
        _isSearching = false;
      });
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
    final paymentsApi = ref.read(paymentsApiProvider);

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
        dropoff: _selectedDropoffAddress != null
            ? {
                'addressLine': _selectedDropoffAddress!,
                'area': _selectedDropoffArea ?? '',
                if (_selectedDropoffLat != null) 'lat': _selectedDropoffLat,
                if (_selectedDropoffLng != null) 'lng': _selectedDropoffLng,
              }
            : null,
      );

      final bookingId = bookingRes.data['bookingId'] as String;

      final paymentInit = await paymentsApi.initiatePayfast(
        bookingId: bookingId,
      );

      final processUrl = paymentInit['processUrl'] as String;
      final payload = Map<String, String>.from(paymentInit['payload'] as Map);

      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PayfastWebViewScreen(
            processUrl: processUrl,
            payload: payload,
          ),
        ),
      );

      if (!mounted) return;

      if (paid == true) {
        _showSnack('Payment initiated. Waiting for confirmation from PayFast.');
      } else {
        _showSnack('Payment cancelled.');
      }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
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
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = _suggestions[i];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined,
                                  color: Colors.grey),
                              title: Text(
                                s.mainText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                s.secondaryText,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () => _selectSuggestion(s),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── Drop-off address ─────────────────────────────────
                    TextField(
                      controller: _dropoffSearchController,
                      onChanged: _onDropoffSearchChanged,
                      decoration: InputDecoration(
                        labelText: 'Drop-off address (optional)',
                        hintText: 'Where should the driver drop you off?',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        suffixIcon: _isDropoffSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _selectedDropoffAddress != null
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),

                    if (_dropoffSuggestions.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(top: 4),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dropoffSuggestions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final s = _dropoffSuggestions[i];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined,
                                  color: Colors.grey),
                              title: Text(
                                s.mainText,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                s.secondaryText,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              onTap: () => _selectDropoffSuggestion(s),
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
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
