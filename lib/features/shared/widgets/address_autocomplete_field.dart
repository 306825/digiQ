import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// Same key used by the passenger pickup address screen
const _kPlacesApiKey = 'AIzaSyBUPxGXp0U0plvCgHl_icV8e2kXuI8CX1A';

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
        'key': _kPlacesApiKey,
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

Future<String?> _fetchFormattedAddress(String placeId) async {
  try {
    final resp = await Dio().get(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: {
        'place_id': placeId,
        'key': _kPlacesApiKey,
        'fields': 'formatted_address',
      },
    );
    return resp.data['result']?['formatted_address'] as String?;
  } catch (_) {
    return null;
  }
}

/// Inline address autocomplete field — same behaviour as the passenger pickup
/// address screen: suggestions appear in a card below the field, selecting one
/// fetches the full formatted address and shows a green tick.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.labelText,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _isConfirmed = false;

  void _onChanged(String value) {
    if (_isConfirmed) setState(() => _isConfirmed = false);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
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
      widget.controller.text = '${s.mainText}, ${s.secondaryText}';
    });

    final formatted = await _fetchFormattedAddress(s.placeId);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _isConfirmed = true;
      if (formatted != null) widget.controller.text = formatted;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Residential Address',
            hintText: 'Start typing your street or suburb…',
            prefixIcon: const Icon(Icons.home_outlined),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _isConfirmed
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
          ),
        ),
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
                  title: Text(
                    s.mainText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    s.secondaryText,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
