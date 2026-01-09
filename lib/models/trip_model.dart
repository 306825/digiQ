class Trip {
  final String id;
  final String driverId;
  final String driverName;
  final String from;
  final String to;
  final DateTime date;
  final int seatsTotal;
  final int seatsAvailable;
  final double price;
  final String status;

  const Trip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.from,
    required this.to,
    required this.date,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.price,
    required this.status,
  });

  /// 🔁 BACKEND → APP
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'] as String,
      driverId: json['driverId'].toString(),
      driverName: json['driverName'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      date: DateTime.parse(json['date']),
      seatsTotal: json['seatsTotal'] as int,
      seatsAvailable: json['seatsAvailable'] as int,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
    );
  }

  /// 🔁 APP → BACKEND (future-proof)
  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'date': date.toIso8601String(),
      'seatsTotal': seatsTotal,
      'price': price,
    };
  }
}
