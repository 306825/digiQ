import 'package:digiQ/features/shared/widgets/user_avatar.dart';
import 'package:digiQ/models/route_model.dart';
import 'package:digiQ/models/trip_model.dart';
import 'package:digiQ/models/trip_search_params.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_search_provider.dart';
import 'trip_details_screen.dart';

class TripSearchResultsScreen extends ConsumerStatefulWidget {
  final RouteModel route;
  final DateTime date;

  const TripSearchResultsScreen({
    super.key,
    required this.route,
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
              routeId: widget.route.id,
              date: widget.date,
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(tripSearchProvider);
    final theme = Theme.of(context);

    final formattedDate = widget.date.toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.route.label),
            Text(
              formattedDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const _LoadingState(),
        error: (error, stack) => _ErrorState(
          error: error,
          onRetry: () {
            ref.read(tripSearchProvider.notifier).search(
                  TripSearchParams(
                    routeId: widget.route.id,
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
            padding: const EdgeInsets.all(20),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _TripCard(
                trip: trip,
                //routeLabel: widget.route.label,
              );
            },
          );
        },
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Trip Card
 * -------------------------------------------------------------------------- */
class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = trip.seatsAvailable == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── LEFT: INFO ─────────────────────────────
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 💰 PRICE
                    Text(
                      'R${trip.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 👤 DRIVER
                    Row(
                      children: [
                        UserAvatar(
                          displayName: trip.driverName,
                          imageUrl: trip.driverProfileImageUrl,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.driverName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 🪑 SEATS REMAINING
                    // 🪑 SEATS ROW (aligned)
                    Row(
                      children: [
                        Text(
                          '${trip.seatsAvailable} seats remaining',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isFull ? Colors.red : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── RIGHT: CAR + TOTAL SEATS ───────────────
              Expanded(
                flex: 6, // 🔥 image dominates
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🚗 CAR IMAGE (BIGGER)
                    SizedBox(
                      height: 150, // 🔥 BIGGER than before
                      child: Image.asset(
                        'assets/branding/image_car_suv.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 🟢 TOTAL SEATS PILL — SOLID GREEN
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${trip.seatsTotal} seats total',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (trip.minPassengers > 1) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 12,
                                color: Colors.orange.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Min ${trip.minPassengers} pax',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Finding available trips...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'No trips available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another route or date.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final Object error;

  const _ErrorState({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            // 🔥 THIS IS WHAT WE NEED
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 20),
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
