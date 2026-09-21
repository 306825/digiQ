import 'package:strut/features/shared/widgets/user_avatar.dart';
import 'package:strut/models/route_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import 'pickup_address_screen.dart';

String _windowLabel(String w) {
  const map = {'08-10': '08:00 – 10:00', '11-13': '11:00 – 13:00', '14-16': '14:00 – 16:00'};
  return map[w] ?? w;
}

class TripDetailsScreen extends ConsumerStatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  String? _selectedDropoffLabel;

  @override
  void initState() {
    super.initState();
    if (widget.trip.dropoffs.length == 1) {
      _selectedDropoffLabel = widget.trip.dropoffs.first.label;
    }
  }

  RouteDropoff? get _selectedDropoff => _selectedDropoffLabel == null
      ? null
      : widget.trip.dropoffs.firstWhere(
          (d) => d.label == _selectedDropoffLabel,
          orElse: () => widget.trip.dropoffs.first,
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = widget.trip;
    final isFull = trip.seatsAvailable == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── ROUTE HEADER ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.from} → ${trip.to}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(trip.date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Departs ${_windowLabel(trip.departureWindow)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trip.offersFreeWifi)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'Free WiFi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── CONTENT ─────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 👤 DRIVER
                    _InfoCard(
                      child: Row(
                        children: [
                          UserAvatar(
                            displayName: trip.driverName,
                            imageUrl: trip.driverProfileImageUrl,
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.driverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              trip.driverRatingCount == 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'New driver',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '⭐ ${trip.driverRating!.toStringAsFixed(1)}  (${trip.driverRatingCount})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🚩 DROP-OFF SELECTOR
                    if (trip.dropoffs.isNotEmpty)
                      _InfoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select your drop-off',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDropoffLabel,
                              decoration: InputDecoration(
                                hintText: 'Choose a drop-off point',
                                prefixIcon: const Icon(Icons.flag_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest,
                              ),
                              items: trip.dropoffs
                                  .map((d) => DropdownMenuItem(
                                        value: d.label,
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(d.label)),
                                            Text(
                                              'R${d.price.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedDropoffLabel = val),
                            ),

                            // Live fare summary
                            if (_selectedDropoff != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fare per seat',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        Text(
                                          'R${_selectedDropoff!.price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.check_circle,
                                      color: theme.colorScheme.primary,
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 🪑 AVAILABILITY
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isFull ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isFull
                                      ? 'FULL'
                                      : '${trip.seatsAvailable} of ${trip.seatsTotal} left',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isFull
                                      ? 'This trip is fully booked'
                                      : 'Seats available',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SeatBar(
                            total: trip.seatsTotal,
                            available: trip.seatsAvailable,
                          ),
                        ],
                      ),
                    ),

                    if (isFull) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Try another date or route to find availability.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── CTA FOOTER ───────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (isFull || _selectedDropoff == null)
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PickupAddressScreen(
                                    trip: trip,
                                    selectedDropoff: _selectedDropoff!,
                                  ),
                                ),
                              );
                            },
                      child: Text(
                        isFull
                            ? 'No seats available'
                            : _selectedDropoff == null
                                ? 'Select a drop-off to continue'
                                : 'Continue — enter pickup address',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  if (!isFull && _selectedDropoff == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Choose your drop-off point above first',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SeatBar extends StatelessWidget {
  final int total;
  final int available;

  const _SeatBar({required this.total, required this.available});

  @override
  Widget build(BuildContext context) {
    final taken = total - available;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total == 0 ? 1 : taken / total,
            minHeight: 8,
            backgroundColor: Colors.green.shade100,
            valueColor: AlwaysStoppedAnimation(
              available == 0 ? Colors.red : Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$taken booked · $available open · $total total',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
