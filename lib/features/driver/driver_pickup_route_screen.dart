import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_providers.dart';
import '../../models/pickup_passenger_model.dart';

class DriverPickupRouteScreen extends ConsumerStatefulWidget {
  final String tripId;

  const DriverPickupRouteScreen({super.key, required this.tripId});

  @override
  ConsumerState<DriverPickupRouteScreen> createState() =>
      _DriverPickupRouteScreenState();
}

class _DriverPickupRouteScreenState
    extends ConsumerState<DriverPickupRouteScreen> {
  List<PickupPassenger>? _passengers;
  bool _calculating = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrCalculate();
  }

  Future<void> _loadOrCalculate() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _calculateRoute();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _calculateRoute() async {
    setState(() { _calculating = true; _error = null; });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final tripsApi = ref.read(tripsApiProvider);
      final result = await tripsApi.calculatePickupRoute(
        widget.tripId,
        driverLat: pos.latitude,
        driverLng: pos.longitude,
      );

      final list = (result['passengers'] as List<dynamic>? ?? [])
          .map((j) => PickupPassenger.fromJson(j as Map<String, dynamic>))
          .toList();

      setState(() => _passengers = list);
    } finally {
      setState(() => _calculating = false);
    }
  }

  Future<void> _navigate(PickupPassenger p) async {
    final Uri uri;
    if (p.hasCoords) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}&travelmode=driving');
    } else {
      final encoded = Uri.encodeComponent('${p.addressLine}, ${p.area}');
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Route'),
        actions: [
          IconButton(
            tooltip: 'Recalculate',
            icon: _calculating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _calculating ? null : _calculateRoute,
          ),
        ],
      ),
      body: _build(context, cs),
    );
  }

  Widget _build(BuildContext context, ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadOrCalculate,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_passengers == null || _passengers!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('No passengers to pick up.'),
          ],
        ),
      );
    }

    final pendingCount = _passengers!.where((p) => !p.isPickedUp).length;
    final doneCount = _passengers!.where((p) => p.isPickedUp).length;

    return RefreshIndicator(
      onRefresh: _calculateRoute,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _CountChip(label: '$pendingCount pending', color: cs.primary),
                  const SizedBox(width: 8),
                  _CountChip(
                      label: '$doneCount picked up', color: Colors.green.shade700),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _PassengerTile(
                passenger: _passengers![i],
                onNavigate: () => _navigate(_passengers![i]),
              ),
              childCount: _passengers!.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _PassengerTile extends StatelessWidget {
  final PickupPassenger passenger;
  final VoidCallback onNavigate;

  const _PassengerTile({required this.passenger, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final picked = passenger.isPickedUp;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sequence badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: picked
                    ? Colors.green.shade100
                    : cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: picked
                  ? Icon(Icons.check, size: 18, color: Colors.green.shade700)
                  : Text(
                      '${passenger.sequenceIndex + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passenger.passengerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration:
                          picked ? TextDecoration.lineThrough : null,
                      color: picked ? cs.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passenger.addressLine,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (passenger.area.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      passenger.area,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                  if (passenger.notes != null &&
                      passenger.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            passenger.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!picked)
              FilledButton.tonalIcon(
                onPressed: onNavigate,
                icon: const Icon(Icons.navigation, size: 16),
                label: const Text('Navigate'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              )
            else
              Chip(
                label: const Text('Picked up'),
                backgroundColor: Colors.green.shade50,
                labelStyle: TextStyle(
                    color: Colors.green.shade700, fontSize: 12),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }
}
