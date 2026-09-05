class DriverBooking {
  final String id;
  final String passengerName;
  final String? passengerPhone;
  final String address;
  final String area;
  final String? notes;
  final String? passengerProfileImageUrl;
  final bool passengerIsVerified;
  final String? dropoffAddress;
  final String? dropoffArea;
  final String? paymentReference;

  DriverBooking({
    required this.id,
    required this.passengerName,
    this.passengerPhone,
    required this.address,
    required this.area,
    this.notes,
    this.passengerProfileImageUrl,
    this.passengerIsVerified = false,
    this.dropoffAddress,
    this.dropoffArea,
    this.paymentReference,
  });

  factory DriverBooking.fromJson(Map<String, dynamic> json) {
    final dropoff = json['dropoff'] as Map<String, dynamic>?;
    return DriverBooking(
      id: json['id'] as String,
      passengerName: json['passengerName'] as String,
      passengerPhone: json['passengerPhone'] as String?,
      passengerProfileImageUrl: json['passengerProfileImageUrl'] as String?,
      passengerIsVerified: json['passengerIsVerified'] as bool? ?? false,
      address: json['pickup']['addressLine'] as String,
      area: json['pickup']['area'] as String,
      notes: json['pickup']['notes'],
      dropoffAddress: dropoff?['addressLine'] as String?,
      dropoffArea: dropoff?['area'] as String?,
      paymentReference: json['paymentReference'] as String?,
    );
  }
}
