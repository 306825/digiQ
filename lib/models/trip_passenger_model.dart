class TripPassenger {
  final String id;
  final String passengerName;
  final String? passengerPhone;
  final String status;
  final String passengerStatus;
  final String addressLine;
  final String area;
  final String? notes;

  const TripPassenger({
    required this.id,
    required this.passengerName,
    this.passengerPhone,
    required this.status,
    required this.passengerStatus,
    required this.addressLine,
    required this.area,
    this.notes,
  });

  factory TripPassenger.fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup'] as Map<String, dynamic>;
    return TripPassenger(
      id: json['id'] as String,
      passengerName: json['passengerName'] as String,
      passengerPhone: json['passengerPhone'] as String?,
      status: json['status'] as String,
      passengerStatus: json['passengerStatus'] as String? ?? 'awaiting_pickup',
      addressLine: pickup['addressLine'] as String,
      area: pickup['area'] as String? ?? '',
      notes: pickup['notes'] as String?,
    );
  }
}
