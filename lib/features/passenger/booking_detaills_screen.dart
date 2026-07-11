import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/theme/app.theme.dart';
import 'package:digiQ/core/api/booking_api.dart';
import 'package:digiQ/core/api/incident_api.dart';
import 'package:digiQ/core/services/tracking_service.dart';
import 'package:digiQ/features/passenger/live_tracking_screen.dart';
import 'package:digiQ/models/booking_model.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  // @override
  // Widget build(BuildContext context) {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             title,
  //             style: Theme.of(context).textTheme.titleMedium,
  //           ),
  //           const SizedBox(height: 12),
  //           ...children,
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

// class _InfoRow extends StatelessWidget {
//   final String label;
//   final String value;

//   const _InfoRow({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Text(
//             '$label:',
//             style: const TextStyle(fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(width: 8),
//           Expanded(child: Text(value)),
//         ],
//       ),
//     );
//   }
// }
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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

final incidentByBookingProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, bookingId) async {
  final api = ref.read(incidentApiProvider);
  return api.getIncidentByBooking(bookingId);
});

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  late TrackingService trackingService;
  bool _joined = false;

  @override
  void initState() {
    super.initState();

    trackingService = TrackingService();

    trackingService
        .connect('https://api.digiqueue.co.za');
  }

  @override
  void dispose() {
    trackingService.disconnect();
    super.dispose();
  }

  Future<void> _confirmPanic(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text(
          'This will send an emergency alert. Only use in real emergencies.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _triggerPanic(context, ref, bookingId);
    }
  }

  Future<void> _triggerPanic(
    BuildContext context,
    WidgetRef ref,
    String bookingId,
  ) async {
    try {
      final tripsApi = ref.read(tripsApiProvider);

      await tripsApi.sendSos(bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency alert sent'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send alert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(passengerBookingsProvider);

    final incidentAsync = ref.watch(
      incidentByBookingProvider(widget.bookingId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: bookingsAsync.when(
        data: (bookings) {
          final bookingOrNull =
              bookings.where((b) => b.id == widget.bookingId).firstOrNull;
          if (bookingOrNull == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final booking = bookingOrNull;

          if (!_joined) {
            _joined = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              trackingService.joinTrip(booking.tripId);

              trackingService.listenToLocation((lat, lng) {});
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoCard(
                  title: 'Booking Info',
                  children: [
                    // _InfoRow(label: 'Passenger', value: booking.passengerName),
                    // _InfoRow(label: 'Pickup', value: booking.pickup.toString()),
                    // _InfoRow(label: 'Status', value: booking.status.name),
                    // _InfoRow(
                    //   label: 'Passenger Status',
                    //   value: booking.passengerStatus.name,
                    // ),
                    _InfoRow(
                      label: 'Passenger',
                      value: booking.passengerName,
                      icon: Icons.person,
                      color: Colors.blue,
                    ),

                    _InfoRow(
                      label: 'Pickup Address',
                      value: booking.pickup.toString(),
                      icon: Icons.location_on,
                      color: Colors.orange,
                    ),

                    _InfoRow(
                      label: 'Booking Status',
                      value: booking.status.name.toUpperCase(),
                      icon: Icons.receipt_long,
                      color: Colors.green,
                    ),

                    _InfoRow(
                      label: 'Passenger Status',
                      value: booking.passengerStatus.name,
                      icon: Icons.directions_car,
                      color: Colors.purple,
                    ),
                    if (booking.passengerStatus ==
                        PassengerStatus.awaitingPickup)
                      ConfirmPickupButton(ref: ref, booking: booking),
                  ],
                ),
                const SizedBox(height: 16),

                // Live tracking — only visible when driver has accepted
                if (booking.status == BookingStatus.approved)
                  _InfoCard(
                    title: 'Track Your Driver',
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on),
                          label: const Text('View Live Location'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveTrackingScreen(
                                  tripId: booking.tripId,
                                  from: booking.pickup.toString(),
                                  passengerStatus: booking.passengerStatus,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                // Share trip details — visible for approved bookings
                if (booking.status == BookingStatus.approved &&
                    booking.driverName != null)
                  _ShareTripCard(booking: booking),

                const SizedBox(height: 16),
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
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text('Report Issue'),
                            onPressed: () {
                              _showReportDialog(context, ref, booking.id);
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error loading incident'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _EmergencyButton(
                  onPressed: () => _confirmPanic(context, ref, booking.id),
                ),
                const SizedBox(height: 8),
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
                final api = ref.read(incidentApiProvider);

                await api.reportIncident(
                  bookingId: bookingId,
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

class ConfirmPickupButton extends StatefulWidget {
  const ConfirmPickupButton({
    super.key,
    required this.ref,
    required this.booking,
  });

  final WidgetRef ref;
  final Booking booking;

  @override
  State<ConfirmPickupButton> createState() => _ConfirmPickupButtonState();
}

class _ConfirmPickupButtonState extends State<ConfirmPickupButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    final bookingApi = widget.ref.read(bookingApiProvider);
                    await bookingApi.confirmPickup(widget.booking.id);
                    widget.ref.invalidate(passengerBookingsProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Pickup confirmed')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to confirm pickup')),
                    );
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm Pickup'),
        ),
      ),
    );
  }
}

class _ShareTripCard extends StatelessWidget {
  final Booking booking;

  const _ShareTripCard({required this.booking});

  String _buildShareText() {
    final parts = <String>['🚌 DigiQ Trip Details'];

    if (booking.routeFrom != null && booking.routeTo != null) {
      parts.add('Route: ${booking.routeFrom} → ${booking.routeTo}');
    }

    if (booking.tripDate != null) {
      final date = DateFormat('EEEE, d MMMM yyyy').format(booking.tripDate!.toLocal());
      final window = booking.departureWindow ?? '';
      parts.add('Date: $date${window.isNotEmpty ? ' ($window)' : ''}');
    }

    parts.add('Pickup: ${booking.pickup}');

    if (booking.driverName != null) {
      parts.add('Driver: ${booking.driverName}');
    }
    if (booking.driverPhone != null) {
      parts.add('Driver phone: ${booking.driverPhone}');
    }
    if (booking.vehicleDescription != null) {
      parts.add('Vehicle: ${booking.vehicleDescription}');
    }
    if (booking.price != null) {
      parts.add('Fare: R${booking.price!.toStringAsFixed(2)}');
    }

    parts.add('\nShared via DigiQ for safety purposes.');
    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.share, color: Colors.green, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Trip Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Let someone know your trip info',
                    style: TextStyle(fontSize: 12, color: Color(0xFF388E3C)),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              onPressed: () => Share.share(_buildShareText()),
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _EmergencyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD50000).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFD50000),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Only use in a real emergency',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE57373),
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD50000),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            onPressed: onPressed,
            child: const Text('SOS'),
          ),
        ],
      ),
    );
  }
}
