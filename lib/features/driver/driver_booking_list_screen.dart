import 'package:digiQ/core/api/booking_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bookings_store_provider.dart';
import '../../models/booking_model.dart';

class DriverBookingListScreen extends ConsumerWidget {
  const DriverBookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsStoreProvider);

    final pendingBookings =
        bookings.where((b) => b.status == BookingStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: pendingBookings.isEmpty
          ? const Center(
              child: Text(
                'No pending booking requests',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: pendingBookings.length,
              itemBuilder: (_, index) {
                final booking = pendingBookings[index];
                return _BookingRequestCard(booking: booking);
              },
            ),
    );
  }
}

class _BookingRequestCard extends ConsumerStatefulWidget {
  final Booking booking;

  const _BookingRequestCard({required this.booking});

  @override
  ConsumerState<_BookingRequestCard> createState() =>
      _BookingRequestCardState();
}

class _BookingRequestCardState extends ConsumerState<_BookingRequestCard>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  BookingStatus? _decision;

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject booking?'),
        content: const Text(
          'Are you sure you want to reject this booking request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _respond(context, BookingStatus.rejected);
    }
  }

  Future<void> _respond(
    BuildContext context,
    BookingStatus status,
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final api = ref.read(bookingApiProvider);

      await api.respondToBooking(
        bookingId: widget.booking.id,
        status: status.name, // approved / rejected
      );

      ref
          .read(bookingsStoreProvider.notifier)
          .updateStatus(widget.booking.id, status);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == BookingStatus.approved
                ? 'Booking accepted'
                : 'Booking rejected',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update booking. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final statusColor = _decision == BookingStatus.approved
        ? Colors.green
        : _decision == BookingStatus.rejected
            ? Colors.red
            : Colors.orange;

    return AnimatedOpacity(
      opacity: _decision == null ? 1 : 0.6,
      duration: const Duration(milliseconds: 300),
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.passengerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_decision != null)
                    Chip(
                      label: Text(
                        _decision == BookingStatus.approved
                            ? 'Approved'
                            : 'Rejected',
                      ),
                      backgroundColor: statusColor.withOpacity(0.15),
                      labelStyle: TextStyle(color: statusColor),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                booking.pickup.toString(),
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _respond(
                                context,
                                BookingStatus.approved,
                              ),
                      child:
                          _isProcessing && _decision == BookingStatus.approved
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isProcessing ? null : () => _confirmReject(context),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
