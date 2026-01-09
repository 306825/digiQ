import 'package:digiQ/models/trip_search_params.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trip_search_provider.dart';
import 'trip_details_screen.dart';

class TripSearchResultsScreen extends ConsumerStatefulWidget {
  final String from;
  final String to;
  final DateTime date;

  const TripSearchResultsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
  });

  @override
  ConsumerState<TripSearchResultsScreen> createState() =>
      _TripSearchResultsScreenState();
}

class _TripSearchResultsScreenState
    extends ConsumerState<TripSearchResultsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(tripSearchProvider.notifier).search(
            TripSearchParams(
              from: widget.from,
              to: widget.to,
              date: widget.date,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.from} → ${widget.to}'),
      ),
      body: tripsAsync.when(
        loading: () => const _LoadingState(),
        error: (error, _) => _ErrorState(
          onRetry: () {
            ref.read(tripSearchProvider.notifier).search(
                  TripSearchParams(
                    from: widget.from,
                    to: widget.to,
                    date: widget.date,
                  ),
                );
          },
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final isFull = trip.seatsAvailable == 0;

              return ListTile(
                enabled: !isFull,
                title: Text(
                  'R${trip.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '${trip.driverName} • ⭐ 1',
                ),
                trailing: Text(
                  isFull ? 'Full' : '${trip.seatsAvailable} seats',
                  style: TextStyle(
                    color: isFull ? Colors.red : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: isFull
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailsScreen(trip: trip),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * UI States
 * -------------------------------------------------------------------------- */

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Searching for available trips...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No trips found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your date or locations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load trips',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
