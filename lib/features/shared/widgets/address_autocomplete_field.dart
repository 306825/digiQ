import 'dart:async';
import 'package:digiQ/core/config/app_keys.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Tappable address field that opens a Google Places Autocomplete bottom sheet.
/// Restricted to South African addresses.
class AddressAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _AddressSearchSheet(controller: controller),
      ),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText ?? 'Residential Address',
            prefixIcon: const Icon(Icons.home_outlined),
            suffixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          ),
          maxLines: 2,
        ),
      ),
    );
  }
}

class _AddressSearchSheet extends StatefulWidget {
  final TextEditingController controller;

  const _AddressSearchSheet({required this.controller});

  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  final _searchCtrl = TextEditingController();
  final _dio = Dio();
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.controller.text;
  }

  Future<void> _search(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': kGooglePlacesApiKey,
          'components': 'country:za',
          'language': 'en',
          'types': 'address',
        },
      );

      final predictions = (response.data['predictions'] as List? ?? []);
      if (mounted) {
        setState(() {
          _suggestions =
              predictions.map((p) => p['description'] as String).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search address…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => _search(v),
                );
              },
            ),
          ),
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(
                    _suggestions[i],
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () {
                    widget.controller.text = _suggestions[i];
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
