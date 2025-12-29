class DriverBooking {
  final String bookingId;
  final String passengerName;
  final String address;
  final String area;
  final String? notes;

  DriverBooking({
    required this.bookingId,
    required this.passengerName,
    required this.address,
    required this.area,
    this.notes,
  });
}
