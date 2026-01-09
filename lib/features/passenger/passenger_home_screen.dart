import 'package:digiQ/features/passenger/my_bookings_screen.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_search_results_screen.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  final fromController = TextEditingController();
  final toController = TextEditingController();
  DateTime? selectedDate;

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  void _searchTrips() {
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripSearchResultsScreen(
          from: fromController.text,
          to: toController.text,
          date: selectedDate!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find a Ride")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: fromController,
              decoration: const InputDecoration(
                labelText: "From",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                labelText: "To",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                selectedDate == null
                    ? "Select date"
                    : selectedDate!.toLocal().toString().split(' ')[0],
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 24),

            // 🔴 THIS IS WHERE THE NAVIGATION CODE LIVES
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _searchTrips,
                child: const Text("Search Trips"),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('DEBUG: Logout (Clear Local Auth)'),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
            ],
            ElevatedButton(
              onPressed: () {
                ref.invalidate(passengerBookingsProvider);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen(),
                  ),
                );
              },
              child: const Text('My Bookings'),
            ),
          ],
        ),
      ),
    );
  }
}
