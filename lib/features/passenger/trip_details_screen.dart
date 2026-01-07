import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import 'pickup_address_screen.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final isFull = trip.seatsLeft == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver
            _Section(
              title: 'Driver',
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${trip.driverName} • ⭐ ${trip.rating}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Price
            _Section(
              title: 'Price',
              child: Text(
                'R${trip.price} per seat',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Availability
            _Section(
              title: 'Availability',
              child: Row(
                children: [
                  Icon(
                    isFull ? Icons.block : Icons.event_seat,
                    color: isFull ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFull
                        ? 'This trip is fully booked'
                        : '${trip.seatsLeft} seats remaining',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isFull ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            if (isFull) ...[
              const SizedBox(height: 12),
              const Text(
                'You can search for another trip or try a different date.',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            const Spacer(),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isFull
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PickupAddressScreen(trip: trip),
                          ),
                        );
                      },
                child: Text(
                  isFull ? 'No Seats Available' : 'Continue',
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Reassurance copy
            const Text(
              'You’ll be asked for a pickup address next.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small reusable layout helper
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
