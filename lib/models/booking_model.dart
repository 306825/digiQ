enum BookingStatus { pending, approved, rejected }

class PickupAddress {
  final String addressLine;
  final String area;
  final String? notes;

  const PickupAddress({
    required this.addressLine,
    required this.area,
    this.notes,
  });

  @override
  String toString() => '$addressLine, $area';

  /* --------------------------------------------------------------------------
   * JSON serialization
   * -------------------------------------------------------------------------- */

  factory PickupAddress.fromJson(Map<String, dynamic> json) {
    return PickupAddress(
      addressLine: json['addressLine'] as String,
      area: json['area'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressLine': addressLine,
      'area': area,
      'notes': notes,
    };
  }
}

class Booking {
  final String id;
  final String tripId;
  final String passengerName;
  final PickupAddress pickup;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.tripId,
    required this.passengerName,
    required this.pickup,
    required this.status,
  });

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      tripId: tripId,
      passengerName: passengerName,
      pickup: pickup,
      status: status ?? this.status,
    );
  }

  /* --------------------------------------------------------------------------
   * JSON serialization
   * -------------------------------------------------------------------------- */

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      passengerName: json['passengerName'] as String,
      pickup: PickupAddress.fromJson(
        json['pickup'] as Map<String, dynamic>,
      ),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'passengerName': passengerName,
      'pickup': pickup.toJson(),
      'status': status.name,
    };
  }
}
