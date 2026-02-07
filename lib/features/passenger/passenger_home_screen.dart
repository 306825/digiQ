import 'package:digiQ/features/passenger/my_bookings_screen.dart';
import 'package:digiQ/models/route_model.dart';
import 'package:digiQ/providers/routes_provider.dart';
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
  RouteModel? selectedRoute;
  DateTime? date;

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Trip'),
        centerTitle: true,
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load routes')),
        data: (routes) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🧭 Logo Header
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/branding/logo_q.png',
                        height: 72,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Plan your journey',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Find trusted drivers going your way',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // 📦 Search Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🛣 Route
                      DropdownButtonFormField<RouteModel>(
                        value: selectedRoute,
                        decoration: const InputDecoration(
                          labelText: 'Route',
                          hintText: 'Select your route',
                        ),
                        items: routes
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedRoute = value);
                        },
                      ),

                      const SizedBox(height: 20),

                      // 📅 Date
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() => date = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Travel date',
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                date == null
                                    ? 'Select date'
                                    : date!.toLocal().toString().split(' ')[0],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 🔍 Search Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: selectedRoute == null || date == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TripSearchResultsScreen(
                                        route: selectedRoute!,
                                        date: date!,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            'Search trips',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 📖 My Bookings
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View my bookings'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyBookingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
