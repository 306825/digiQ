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
  forfeited,
}

PaymentStatus _parsePaymentStatus(dynamic value) {
  switch (value.toString()) {
    case 'pending':
      return PaymentStatus.pending;
    case 'paid':
      return PaymentStatus.paid;
    case 'refunded':
      return PaymentStatus.refunded;
    case 'forfeited':
      return PaymentStatus.forfeited;
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
  final DateTime? tripDate;
  final String? departureWindow;
  final String? routeFrom;
  final String? routeTo;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleDescription;
  final double? price;

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
    this.tripDate,
    this.departureWindow,
    this.routeFrom,
    this.routeTo,
    this.driverName,
    this.driverPhone,
    this.vehicleDescription,
    this.price,
  });

  /// Returns true when the trip departs in less than 24 hours (local time).
  bool get isWithin24HoursOfDeparture {
    if (tripDate == null) return false;
    final window = departureWindow ?? '08-10';
    final startHour = window.startsWith('08') ? 8 : window.startsWith('11') ? 11 : 14;
    final departure = DateTime(
      tripDate!.toLocal().year,
      tripDate!.toLocal().month,
      tripDate!.toLocal().day,
      startHour,
    );
    return departure.difference(DateTime.now()).inHours < 24;
  }

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
      tripDate: tripDate,
      departureWindow: departureWindow,
      routeFrom: routeFrom,
      routeTo: routeTo,
      driverName: driverName,
      driverPhone: driverPhone,
      vehicleDescription: vehicleDescription,
      price: price,
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
      status: _parseBookingStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      passengerStatus: json['passengerStatus'] != null
          ? _parsePassengerStatus(json['passengerStatus'])
          : PassengerStatus.awaitingPickup,
      paymentStatus: _parsePaymentStatus(json['paymentStatus']),
      tripDate: json['tripDate'] != null ? DateTime.parse(json['tripDate']) : null,
      departureWindow: json['departureWindow'] as String?,
      routeFrom: json['routeFrom'] as String?,
      routeTo: json['routeTo'] as String?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      vehicleDescription: json['vehicleDescription'] as String?,
      price: (json['price'] as num?)?.toDouble(),
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
