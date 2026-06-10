//enum BookingStatus { pending, approved, rejected }
enum BookingStatus {
  awaitingPayment,
  pending,
  approved,
  rejected,
  cancelled,
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
}

PaymentStatus _parsePaymentStatus(dynamic value) {
  switch (value.toString()) {
    case 'pending':
      return PaymentStatus.pending;

    case 'paid':
      return PaymentStatus.paid;

    case 'refunded':
      return PaymentStatus.refunded;

    default:
      throw Exception('Unknown payment status: $value');
  }
}

BookingStatus _parseBookingStatus(dynamic value) {
  switch (value.toString()) {
    case 'awaiting_payment':
      return BookingStatus.awaitingPayment;

    case 'pending':
      return BookingStatus.pending;

    case 'approved':
      return BookingStatus.approved;

    case 'rejected':
      return BookingStatus.rejected;

    case 'cancelled':
      return BookingStatus.cancelled;

    default:
      throw Exception('Unknown booking status: $value');
  }
}

PassengerStatus _parsePassengerStatus(dynamic value) {
  switch (value.toString()) {
    case 'awaiting_pickup':
      return PassengerStatus.awaitingPickup;

    case 'picked_up':
      return PassengerStatus.pickedUp;

    case 'dropped_off':
      return PassengerStatus.droppedOff;

    default:
      throw Exception('Unknown passenger status: $value');
  }
}

enum PassengerStatus {
  awaitingPickup,
  pickedUp,
  droppedOff,
}

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
  final DateTime updatedAt;
  final DateTime createdAt;
  final PassengerStatus passengerStatus;
  final PaymentStatus paymentStatus;

  const Booking({
    required this.id,
    required this.tripId,
    required this.passengerName,
    required this.pickup,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.passengerStatus,
    required this.paymentStatus,
  });

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      tripId: tripId,
      passengerName: passengerName,
      pickup: pickup,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      passengerStatus: passengerStatus,
      paymentStatus: paymentStatus,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      tripId: json['tripId'].toString(),
      passengerName: (json['passengerName'] as String?) ?? 'Unknown passenger',
      pickup: PickupAddress.fromJson(
        json['pickup'] as Map<String, dynamic>,
      ),
      // status: BookingStatus.values.firstWhere(
      //   (e) => e.name == json['status'],
      // ),
      status: _parseBookingStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      //passengerStatus: PassengerStatus.values.firstWhere(
      //  (e) => e.name == json['passengerStatus'].toString().replaceAll('_', ''),
      //),
      //passengerStatus: _parsePassengerStatus([json['passengerStatus']]),
      passengerStatus: json['passengerStatus'] != null
          ? _parsePassengerStatus(json['passengerStatus'])
          : PassengerStatus.awaitingPickup,
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
    );
  }

  factory Booking.fromDriverPendingJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String, // ✅ backend sends `id`, not `_id`
      tripId: '', // ❌ not provided for drivers (safe empty)
      passengerName: (json['passengerName'] as String?) ?? 'Unknown passenger',
      pickup: PickupAddress.fromJson(
        json['pickup'] as Map<String, dynamic>,
      ),
      //status: BookingStatus.values.firstWhere(
      //  (e) => e.name == json['status'],
      //),
      status: _parseBookingStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['createdAt']),
      // reuse createdAt
      // passengerStatus: PassengerStatus.values.firstWhere(
      //   (e) => e.name == json['passengerStatus'].toString().replaceAll('_', ''),
      // ),
      passengerStatus: _parsePassengerStatus([json['passengerStatus']]),
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
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
