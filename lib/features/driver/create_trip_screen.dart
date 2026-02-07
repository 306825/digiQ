import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/departure_window.dart';
import 'package:digiQ/models/route_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:digiQ/providers/driver_trips_provider.dart';
import 'package:digiQ/providers/routes_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  RouteModel? selectedRoute;
  final seatsCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  DateTime? date;
  bool submitting = false;
  DepartureWindow? selectedWindow;

  Future<void> submit() async {
    if (selectedRoute == null || selectedWindow == null || date == null) return;

    final seats = int.tryParse(seatsCtrl.text);
    final price = double.tryParse(priceCtrl.text);

    if (seats == null || seats <= 0 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid seats and price')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      print('🚀 Creating trip...');
      print('routeId=${selectedRoute!.id}');
      print('window=${selectedWindow!.apiValue}');
      print('date=$date seats=$seats price=$price');

      await ref.read(tripsApiProvider).createTrip(
            routeId: selectedRoute!.id,
            departureWindow: selectedWindow!.apiValue,
            date: date!,
            seatsTotal: seats,
            price: price,
          );

      ref.invalidate(driverTripsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip created successfully')),
        );
      }
    } catch (e, stack) {
      print('❌ CREATE TRIP FAILED');
      print(e);
      print(stack);

      if (e is DioException && e.response?.statusCode == 403) {
        await ref.read(authProvider.notifier).refreshMe();
        return; // 🚨 stop further UI handling
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create trip')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: routesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Failed to load routes')),
          data: (routes) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Trip Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _FormCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<RouteModel>(
                      value: selectedRoute,
                      hint: const Text('Select Route'),
                      decoration: const InputDecoration(
                        labelText: 'Route',
                        prefixIcon: Icon(Icons.route),
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

                    const SizedBox(height: 12),

// ⏰ Departure Window
                    DropdownButtonFormField<DepartureWindow>(
                      value: selectedWindow,
                      hint: const Text('Select departure time'),
                      decoration: const InputDecoration(
                        labelText: 'Departure window',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: DepartureWindow.values
                          .map(
                            (w) => DropdownMenuItem(
                              value: w,
                              child: Text(w.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedWindow = value);
                      },
                    ),

                    const SizedBox(height: 12),

                    const SizedBox(height: 12),
                    TextField(
                      controller: seatsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Available seats',
                        prefixIcon: Icon(Icons.event_seat),
                        hintText: 'e.g. 3',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price per seat',
                        prefixIcon: Icon(Icons.payments),
                        hintText: 'e.g. 350',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DatePickerTile(
                      date: date,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    submitting ? 'Creating trip...' : 'Publish Trip',
                  ),
                  onPressed: submitting ? null : submit,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Passengers will be able to book this trip immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------------------------------------------------------
 * Reusable UI Components
 * -------------------------------------------------------------------------- */

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? 'Select trip date'
        : date!.toLocal().toString().split(' ')[0];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

//red onion, garlic cinamon ginger and honey
//harman balsum kopifa, perminunt, dalington, jaimaic gemer, waverland
