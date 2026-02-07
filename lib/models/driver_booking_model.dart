class DriverBooking {
  final String id;
  final String passengerName;
  final String address;
  final String area;
  final String? notes;
  final String? passengerProfileImageUrl;

  DriverBooking({
    required this.id,
    required this.passengerName,
    required this.address,
    required this.area,
    this.notes,
    this.passengerProfileImageUrl,
  });

  factory DriverBooking.fromJson(Map<String, dynamic> json) {
    return DriverBooking(
      id: json['id'] as String,
      passengerName: json['passengerName'] as String,
      passengerProfileImageUrl: json['passengerProfileImageUrl'] as String?,
      address: json['pickup']['addressLine'] as String,
      area: json['pickup']['area'] as String,
      notes: json['pickup']['notes'],
    );
  }
}
