class Trip {
  final String id;
  final String driverName;
  final double rating;
  final int price;
  final int seatsLeft;

  Trip({
    required this.id,
    required this.driverName,
    required this.rating,
    required this.price,
    required this.seatsLeft,
  });
}

class TripSearchParams {
  final String from;
  final String to;
  final DateTime date;

  TripSearchParams({required this.from, required this.to, required this.date});
}
