import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import 'pickup_address_screen.dart';

class TripDetailsScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Driver',
              child: Text(
                '${trip.driverName} • ⭐ ${trip.rating}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Price',
              child: Text(
                'R${trip.price} per seat',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _Section(
              title: 'Availability',
              child: Text(
                '${trip.seatsLeft} seats remaining',
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const Spacer(),

            // 🔴 THIS BUTTON DRIVES THE FLOW FORWARD
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: trip.seatsLeft == 0
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PickupAddressScreen(tripId: trip.id),
                          ),
                        );
                      },
                child: const Text('Continue'),
              ),
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
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
