import 'package:digiQ/models/booking_entity.dart';

class PickupAddress {
  final String addressLine;
  final String area;
  final String? notes;

  PickupAddress({required this.addressLine, required this.area, this.notes});
}

enum BookingUiStatus { idle, loading, success, error }

class Booking {
  final String id;
  final String tripId;
  final PickupAddress pickup;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.tripId,
    required this.pickup,
    required this.status,
  });
}
