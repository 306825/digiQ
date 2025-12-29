enum BookingStatus { pending, confirmed, rejected }

class BookingEntity {
  final String id;
  final String tripId;
  final String passengerName;
  final String pickupAddress;
  final BookingStatus status;

  BookingEntity({
    required this.id,
    required this.tripId,
    required this.passengerName,
    required this.pickupAddress,
    required this.status,
  });

  BookingEntity copyWith({BookingStatus? status}) {
    return BookingEntity(
      id: id,
      tripId: tripId,
      passengerName: passengerName,
      pickupAddress: pickupAddress,
      status: status ?? this.status,
    );
  }
}
