import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trip_model.dart';
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

    // 🔴 Trigger the search ONCE when screen loads
    Future.microtask(() {
      ref
          .read(tripSearchProvider.notifier)
          .search(
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
      appBar: AppBar(title: Text('${widget.from} → ${widget.to}')),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load trips')),
        data: (trips) {
          if (trips.isEmpty) {
            return const Center(child: Text('No trips found'));
          }

          return ListView.separated(
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final Trip trip = trips[index];

              return ListTile(
                title: Text(
                  'R${trip.price}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${trip.driverName} • ⭐ ${trip.rating}'),
                trailing: Text('${trip.seatsLeft} seats'),
                onTap: () {
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
