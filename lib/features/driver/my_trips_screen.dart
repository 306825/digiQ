import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trip_model.dart';
import '../../providers/driver_trips_provider.dart';
import 'driver_trip_detail_screen.dart';
import 'dart:async';

import 'package:digiQ/core/api/trips_api.dart';
import 'package:geolocator/geolocator.dart';

// Dio instance used by the location-push timer (outside widget tree).
TripsApi? _tripsApi;

Timer? trackingTimer;
String? activeTripId;

/* --------------------------------------------------------------------------
 * Module-level tracking helpers (use module-level state above)
 * -------------------------------------------------------------------------- */

Future<void> startTracking(String tripId) async {
  if (activeTripId == tripId) return;

  debugPrint('[TRACKING] Starting HTTP tracking for trip: $tripId');

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    debugPrint('[TRACKING] Location services DISABLED');
    return;
  }

  var permission = await Geolocator.checkPermission();
  debugPrint('[TRACKING] Permission: $permission');
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    debugPrint('[TRACKING] Permission denied forever');
    return;
  }

  activeTripId = tripId;

  // Push an immediate fix from the last known position.
  Geolocator.getLastKnownPosition().then((pos) async {
    if (pos != null && _tripsApi != null) {
      try {
        await _tripsApi!.postLocation(tripId, pos.latitude, pos.longitude);
        debugPrint('[TRACKING] Last known position posted: ${pos.latitude}, ${pos.longitude}');
      } catch (_) {}
    }
  });

  trackingTimer?.cancel();
  trackingTimer = Timer.periodic(
    const Duration(seconds: 5),
    (_) async {
      if (_tripsApi == null) return;
      try {
        final position = await Geolocator.getCurrentPosition();
        await _tripsApi!.postLocation(tripId, position.latitude, position.longitude);
        debugPrint('[TRACKING] Location posted: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('[TRACKING] Failed: $e');
      }
    },
  );
}

void stopTracking() {
  trackingTimer?.cancel();
  trackingTimer = null;
  activeTripId = null;
}

/* --------------------------------------------------------------------------
 * Screen
 * -------------------------------------------------------------------------- */

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep _tripsApi up to date so the module-level timer can use it.
    _tripsApi = ref.read(tripsApiProvider);

    final tripsAsync = ref.watch(driverTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        centerTitle: true,
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _ErrorState(),
        data: (trips) {
          // Auto-resume tracking if there is an active trip but the timer
          // is not running (e.g. app restarted while a trip was in progress).
          if (activeTripId == null) {
            final activeTrip =
                trips.where((t) => t.status == 'active').firstOrNull;
            if (activeTrip != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                startTracking(activeTrip.id);
              });
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(driverTripsProvider.notifier).refresh();
            },
            child: trips.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, index) {
                      try {
                        return _TripCard(trip: trips[index]);
                      } catch (e, st) {
                        print("🔥 CRASH RENDERING TRIP INDEX $index: $e");
                        print(st);
                        return const SizedBox.shrink();
                      }
                    },
                  ),
          );
        },
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Empty + Error States
 * -------------------------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 180),
        Center(
          child: Column(
            children: [
              Icon(Icons.route, size: 52, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No trips yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Create your first trip to start receiving bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 12),
          Text(
            'Failed to load trips',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Pull down to retry',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Trip Card
 * -------------------------------------------------------------------------- */

class _TripCard extends ConsumerWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("RENDERING TRIP: ${trip.toJson()}");

    final status = trip.status ?? 'scheduled';

    final isScheduled = status == 'scheduled';
    final isActive = status == 'active';
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final statusColor = isActive
        ? Colors.green
        : isCancelled
            ? Colors.red
            : Colors.grey;

    return Card(
      elevation: 0.6,
      shadowColor: Colors.black12,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverTripDetailScreen(trip: trip),
          ),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROUTE + PRICE
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${trip.from.isNotEmpty ? trip.from : "Unknown"} → '
                    '${trip.to.isNotEmpty ? trip.to : "Unknown"}',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'R ${trip.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // DATE
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  trip.date != null
                      ? _formatDate(trip.date)
                      : 'Date unavailable',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PILLS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: Icons.event_seat,
                  label:
                      '${trip.seatsAvailable ?? 0}/${trip.seatsTotal ?? 0} seats',
                  color: Colors.blueGrey,
                ),
                _Pill(
                  icon: isActive
                      ? Icons.play_arrow
                      : isCompleted
                          ? Icons.check
                          : isCancelled
                              ? Icons.cancel
                              : Icons.schedule,
                  label: status.toUpperCase(),
                  color: isActive
                      ? Colors.green
                      : isCompleted
                          ? Colors.grey
                          : isCancelled
                              ? Colors.red
                              : Colors.orange,
                ),
                if (trip.minPassengers > 1)
                  _Pill(
                    icon: Icons.group,
                    label: 'Min ${trip.minPassengers}',
                    color: Colors.blueGrey,
                  ),
                if (isScheduled) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final tripsApi = ref.read(tripsApiProvider);
                          _tripsApi = tripsApi;
                          await tripsApi.startTrip(trip.id);
                          await startTracking(trip.id);
                          await ref
                              .read(driverTripsProvider.notifier)
                              .refresh();
                        },
                        child: const Text('Start Trip'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                        onPressed: () => _confirmCancel(context, ref),
                        child: const Text('Cancel Trip'),
                      ),
                    ),
                  ),
                ],

                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final tripsApi = ref.read(tripsApiProvider);
                          await tripsApi.completeTrip(trip.id);
                          stopTracking();
                          await ref
                              .read(driverTripsProvider.notifier)
                              .refresh();
                        },
                        child: const Text('Complete Trip'),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel trip?'),
        content: const Text(
          'This will cancel the trip and refund all passengers who have already paid. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep trip'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final result = await ref.read(tripsApiProvider).cancelTrip(trip.id);
      final refunded = result['refundedBookings'] as int? ?? 0;
      await ref.read(driverTripsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              refunded > 0
                  ? 'Trip cancelled. $refunded passenger${refunded == 1 ? '' : 's'} will be refunded.'
                  : 'Trip cancelled.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel trip')),
        );
      }
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/* --------------------------------------------------------------------------
 * Reusable Pill
 * -------------------------------------------------------------------------- */

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
