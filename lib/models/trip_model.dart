class Trip {
  final String id;
  final String driverId;
  final String driverName;

  final String from;
  final String to;

  final DateTime date;
  final String departureWindow;

  final int seatsTotal;
  final int seatsAvailable;
  final double price;

  final String status;
  final String? driverProfileImageUrl;

  const Trip({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.from,
    required this.to,
    required this.date,
    required this.departureWindow,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.price,
    required this.status,
    this.driverProfileImageUrl,
  });

  /* --------------------------------------------------------------------------
   * BACKEND → APP (Driver / Mongo shape)
   * -------------------------------------------------------------------------- */
  factory Trip.fromJson(Map<String, dynamic> json) {
    final snapshot = json['routeSnapshot'] as Map<String, dynamic>?;

    return Trip(
      id: json['_id'].toString(),
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName'] ?? 'Driver',
      from: snapshot?['fromLabel'] ?? 'Unknown',
      to: snapshot?['toLabel'] ?? 'Unknown',
      date: DateTime.parse(json['date'] as String),
      departureWindow: json['departureWindow'] ?? 'Unspecified',
      seatsTotal: (json['seatsTotal'] as num).toInt(),
      seatsAvailable: (json['seatsAvailable'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num).toDouble(),
      status: json['status'] ?? 'closed',
    );
  }

  /* --------------------------------------------------------------------------
   * BACKEND → APP (Passenger search DTO)
   * -------------------------------------------------------------------------- */
  factory Trip.fromSearchJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,

      // 🔹 Not provided by search DTO
      driverId: '',

      driverName: json['driverName'] as String,

      from: json['route']['from'] as String,
      to: json['route']['to'] as String,

      date: DateTime.parse(json['date'] as String),
      departureWindow: (json['departureWindow'] as String?) ?? 'Unspecified',

      seatsTotal: json['seatsTotal'] as int,
      seatsAvailable: json['seatsAvailable'] as int,
      price: (json['price'] as num).toDouble(),

      // 🔹 Search results are always open
      status: 'open',

      // 🖼️ THIS WAS MISSING
      driverProfileImageUrl: json['driverProfileImageUrl'] as String?,
    );
  }

  /* --------------------------------------------------------------------------
   * APP → BACKEND (future-proof)
   * -------------------------------------------------------------------------- */
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'driverName': driverName,
      'from': from,
      'to': to,
      'date': date.toIso8601String(),
      'departureWindow': departureWindow,
      'seatsTotal': seatsTotal,
      'seatsAvailable': seatsAvailable,
      'price': price,
      'status': status,
      'driverProfileImageUrl': driverProfileImageUrl,
    };
  }
}
