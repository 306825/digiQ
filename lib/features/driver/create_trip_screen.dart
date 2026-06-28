import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/models/departure_window.dart';
import 'package:digiQ/models/route_model.dart';
import 'package:digiQ/models/vehicle_model.dart';
import 'package:digiQ/providers/driver_trips_provider.dart';
import 'package:digiQ/providers/driver_vehicle_provider.dart';
import 'package:digiQ/providers/routes_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  RouteModel? selectedRoute;
  VehicleModel? selectedVehicle;
  final priceCtrl = TextEditingController();
  DateTime? date;
  bool submitting = false;
  DepartureWindow? selectedWindow;
  int minPassengers = 1;

  Future<void> submit() async {
    if (selectedRoute == null || selectedWindow == null || date == null) return;

    if (selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    // Guard: reject if the selected window has already passed for today
    if (selectedWindow!.isExpiredForDate(date!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The ${selectedWindow!.label} window has already passed today. '
            'Please choose a later window or a future date.',
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      await ref.read(tripsApiProvider).createTrip(
            routeId: selectedRoute!.id,
            departureWindow: selectedWindow!.apiValue,
            date: date!,
            vehicleId: selectedVehicle!.id,
            price: price,
            minPassengers: minPassengers,
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

      //if (e is DioException && e.response?.statusCode == 403) {
      if (e is DioException) {
        print('--------------------------------------------------------------');
        print('🔴 STATUS: ${e.response?.statusCode}');
        print('🔴 DATA: ${e.response?.data}');
        print('🔴 MESSAGE: ${e.message}');
        //await ref.read(authProvider.notifier).refreshMe();
        //return; // 🚨 stop further UI handling
      }
      print(
          '-------------------------check mount-------------------------------------');

      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;

        if (data['code'] == 'LICENSE_EXPIRED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Your driver license has expired. Please update it.'),
            ),
          );
          return;
        }
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
    final vehiclesAsync = ref.watch(driverVehicleProvider);

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

                    // ── Date (must be picked before window) ──────────────
                    _DatePickerTile(
                      date: date,
                      onTap: () async {
                        final today = DateTime.now();
                        final todayOnly =
                            DateTime(today.year, today.month, today.day);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: todayOnly,
                          firstDate: todayOnly,
                          lastDate: todayOnly.add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() {
                            date = picked;
                            // Drop the window if it has already passed on this date
                            if (selectedWindow != null &&
                                selectedWindow!.isExpiredForDate(picked)) {
                              selectedWindow = null;
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── Departure Window (only available after date picked) ──
                    Builder(builder: (context) {
                      final available = date == null
                          ? DepartureWindow.values
                          : DepartureWindow.values
                              .where((w) => !w.isExpiredForDate(date!))
                              .toList();

                      return DropdownButtonFormField<DepartureWindow>(
                        key: ValueKey(date),
                        initialValue: selectedWindow,
                        hint: Text(
                          date == null
                              ? 'Pick a date first'
                              : available.isEmpty
                                  ? 'No windows available today'
                                  : 'Select departure time',
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Departure window',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: available
                            .map((w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.label),
                                ))
                            .toList(),
                        onChanged: date == null || available.isEmpty
                            ? null
                            : (value) => setState(() => selectedWindow = value),
                      );
                    }),

                    const SizedBox(height: 12),
                    vehiclesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text(
                        'Failed to load vehicles',
                        style: TextStyle(color: Colors.red),
                      ),
                      data: (vehicles) {
                        final approved = vehicles
                            .where((v) => v.isApproved)
                            .toList();
                        if (approved.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_outlined,
                                    color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No approved vehicles yet. Add and submit a vehicle for review first.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<VehicleModel>(
                              value: selectedVehicle,
                              hint: const Text('Select vehicle'),
                              decoration: const InputDecoration(
                                labelText: 'Vehicle',
                                prefixIcon: Icon(Icons.directions_car_outlined),
                              ),
                              items: approved
                                  .map((v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v.displayName),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedVehicle = v),
                            ),
                            if (selectedVehicle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 4),
                                child: Text(
                                  '${selectedVehicle!.seats} seat${selectedVehicle!.seats == 1 ? '' : 's'} available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
                    _MinPassengersStepper(
                      value: minPassengers,
                      onChanged: (v) => setState(() => minPassengers = v),
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

class _MinPassengersStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _MinPassengersStepper({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.group, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Minimum passengers',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'Need at least $value passenger${value == 1 ? '' : 's'} to proceed',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            color: Colors.grey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

//red onion, garlic cinamon ginger and honey
//harman balsum kopifa, perminunt, dalington, jaimaic gemer, waverland
