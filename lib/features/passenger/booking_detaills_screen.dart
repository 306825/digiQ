import 'package:digiQ/core/api/incident_api.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final incidentByBookingProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, bookingId) async {
  final api = ref.read(incidentApiProvider);
  return api.getIncidentByBooking(bookingId);
});

class BookingDetailsScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(passengerBookingsProvider);
    // final incidentFuture = ref.watch(
    //   FutureProvider((ref) {
    //     final api = ref.read(incidentApiProvider);
    //     return api.getIncidentByBooking(bookingId);
    //   }),
    // );
    final incidentAsync = ref.watch(
      incidentByBookingProvider(bookingId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: bookingsAsync.when(
        data: (bookings) {
          final booking = bookings.firstWhere((b) => b.id == bookingId);

          // return Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text('Passenger: ${booking.passengerName}'),
          //       const SizedBox(height: 8),
          //       Text('Pickup: ${booking.pickup}'),
          //       const SizedBox(height: 8),
          //       Text('Status: ${booking.status.name}'),
          //       const SizedBox(height: 24),
          //       incidentAsync.when(
          //         data: (incident) {
          //           if (incident != null) {
          //             return Container(
          //               padding: const EdgeInsets.all(12),
          //               decoration: BoxDecoration(
          //                 color: Colors.orange.withOpacity(0.1),
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //               child: Text(
          //                 'Incident status: ${incident['status']}',
          //                 style: const TextStyle(fontWeight: FontWeight.bold),
          //               ),
          //             );
          //           }

          //           return ElevatedButton(
          //             style: ElevatedButton.styleFrom(
          //               backgroundColor: Colors.red,
          //             ),
          //             onPressed: () {
          //               _showReportDialog(context, ref, booking.id);
          //             },
          //             child: const Text('Report Issue'),
          //           );
          //         },
          //         loading: () =>
          //             Center(child: const CircularProgressIndicator()),
          //         error: (_, __) => const Text('Error loading incident'),
          //       ),
          //     ],
          //   ),
          // );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoCard(
                  title: 'Booking Info',
                  children: [
                    _InfoRow(label: 'Passenger', value: booking.passengerName),
                    _InfoRow(label: 'Pickup', value: booking.pickup.toString()),
                    _InfoRow(label: 'Status', value: booking.status.name),
                  ],
                ),
                const SizedBox(height: 16),

                // INCIDENT SECTION
                _InfoCard(
                  title: 'Support',
                  children: [
                    incidentAsync.when(
                      data: (incident) {
                        if (incident != null) {
                          return _StatusChip(status: incident['status']);
                        }

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              _showReportDialog(context, ref, booking.id);
                            },
                            child: const Text('Report Issue'),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => const Text('Error loading incident'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading booking')),
      ),
    );
  }

  void _showReportDialog(
      BuildContext context, WidgetRef ref, String bookingId) {
    String selectedType = 'safety';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Report Issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'safety', child: Text('Safety')),
                  DropdownMenuItem(value: 'payment', child: Text('Payment')),
                  DropdownMenuItem(
                      value: 'driver_behavior', child: Text('Driver behavior')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) => selectedType = val!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final api =
                    ref.read(incidentApiProvider); // or incidentApi later

                await api.reportIncident(
                  bookingId: bookingId, // TEMP (we fix backend next)
                  type: selectedType,
                  description: controller.text,
                );
                ref.invalidate(incidentByBookingProvider(bookingId));

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incident reported')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color _getColor() {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_review':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Incident status: ${status.toUpperCase()}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
