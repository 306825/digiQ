class PickupPassenger {
  final String bookingId;
  final String passengerName;
  final String? passengerPhone;
  final String passengerStatus;
  final int sequenceIndex;
  final String addressLine;
  final String area;
  final double? lat;
  final double? lng;
  final String? notes;

  const PickupPassenger({
    required this.bookingId,
    required this.passengerName,
    this.passengerPhone,
    required this.passengerStatus,
    required this.sequenceIndex,
    required this.addressLine,
    required this.area,
    this.lat,
    this.lng,
    this.notes,
  });

  bool get isPickedUp => passengerStatus == 'picked_up';
  bool get hasCoords => lat != null && lng != null;

  factory PickupPassenger.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup'] as Map<String, dynamic>;
    return PickupPassenger(
      bookingId: json['bookingId'] as String,
      passengerName: json['passengerName'] as String? ?? 'Passenger',
      passengerPhone: json['passengerPhone'] as String?,
      passengerStatus: json['passengerStatus'] as String? ?? 'awaiting_pickup',
      sequenceIndex: json['sequenceIndex'] as int? ?? 0,
      addressLine: pickup['addressLine'] as String? ?? '',
      area: pickup['area'] as String? ?? '',
      lat: (pickup['lat'] as num?)?.toDouble(),
      lng: (pickup['lng'] as num?)?.toDouble(),
      notes: pickup['notes'] as String?,
    );
  }
}
