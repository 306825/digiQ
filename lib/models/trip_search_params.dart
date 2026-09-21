class TripSearchParams {
  final String routeId;
  final DateTime date;
  final String? driverEmail;

  const TripSearchParams({
    required this.routeId,
    required this.date,
    this.driverEmail,
  });
}
