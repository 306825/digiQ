import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/driver_follows_api.dart';
import 'package:strut/features/shared/widgets/user_avatar.dart';
import 'package:strut/models/driver_follow_model.dart';
import 'package:strut/providers/driver_follows_provider.dart';

class DriverPublicProfileScreen extends ConsumerStatefulWidget {
  final String driverId;

  const DriverPublicProfileScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverPublicProfileScreen> createState() =>
      _DriverPublicProfileScreenState();
}

class _DriverPublicProfileScreenState
    extends ConsumerState<DriverPublicProfileScreen> {
  bool _toggling = false;

  Future<void> _toggleFollow(bool currentlyFollowing) async {
    setState(() => _toggling = true);
    try {
      final api = ref.read(driverFollowsApiProvider);
      if (currentlyFollowing) {
        await api.unfollow(widget.driverId);
      } else {
        await api.follow(widget.driverId);
      }
      ref.invalidate(driverProfileProvider(widget.driverId));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(driverProfileProvider(widget.driverId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Failed to load profile'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(driverProfileProvider(widget.driverId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Avatar
                UserAvatar(
                  displayName: profile.fullName,
                  imageUrl: profile.profileImageUrl,
                  size: 96,
                ),

                const SizedBox(height: 16),

                Text(
                  profile.fullName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Rating
                if (profile.ratingCount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        profile.ratingAvg!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${profile.ratingCount} reviews)',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'New driver',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],

                const SizedBox(height: 24),

                // Follow / Unfollow button
                SizedBox(
                  width: double.infinity,
                  child: profile.following
                      ? OutlinedButton.icon(
                          icon: _toggling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.person_remove_outlined,
                                  size: 18),
                          label: const Text('Unfollow'),
                          onPressed: _toggling
                              ? null
                              : () => _toggleFollow(true),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      : FilledButton.icon(
                          icon: _toggling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.person_add_outlined,
                                  size: 18),
                          label: const Text('Follow'),
                          onPressed: _toggling
                              ? null
                              : () => _toggleFollow(false),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Stats card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver Stats',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _StatRow(
                        icon: Icons.people_outline,
                        label: 'Followers',
                        value: profile.followerCount.toString(),
                      ),
                      if (profile.ratingCount > 0) ...[
                        const SizedBox(height: 12),
                        _StatRow(
                          icon: Icons.star_outline_rounded,
                          label: 'Average rating',
                          value:
                              '${profile.ratingAvg!.toStringAsFixed(1)} / 5.0',
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          icon: Icons.rate_review_outlined,
                          label: 'Total reviews',
                          value: profile.ratingCount.toString(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Upcoming trips
                _UpcomingTripsSection(driverId: widget.driverId),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/* --------------------------------------------------------------------------
 * Upcoming trips section
 * -------------------------------------------------------------------------- */

class _UpcomingTripsSection extends ConsumerWidget {
  final String driverId;
  const _UpcomingTripsSection({required this.driverId});

  String _windowLabel(String w) {
    const map = {
      '08-10': '08:00 – 10:00',
      '11-13': '11:00 – 13:00',
      '14-16': '14:00 – 16:00',
    };
    return map[w] ?? w;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(driverUpcomingTripsProvider(driverId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Trips',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        tripsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const Text(
            'Could not load upcoming trips.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          data: (trips) {
            if (trips.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.directions_car_outlined,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'No upcoming trips scheduled',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _TripRow(
                trip: trips[i],
                windowLabel: _windowLabel(trips[i].departureWindow),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TripRow extends StatelessWidget {
  final DriverUpcomingTrip trip;
  final String windowLabel;

  const _TripRow({required this.trip, required this.windowLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.date,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  windowLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Route
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.from} → ${trip.to}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.seatsAvailable} of ${trip.seatsTotal} seats left',
                  style: TextStyle(
                      fontSize: 12,
                      color: trip.seatsAvailable == 0
                          ? Colors.red
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
