import 'package:strut/models/route_model.dart';

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
  final List<RouteDropoff> dropoffs;
  final int minPassengers;
  final double totalAmountPaid;

  final String status;
  final String? driverProfileImageUrl;
  final double? driverRating;
  final int driverRatingCount;
  final bool offersFreeWifi;
  final bool isFollowedDriver;

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
    required this.dropoffs,
    required this.status,
    this.minPassengers = 1,
    this.totalAmountPaid = 0,
    this.driverProfileImageUrl,
    this.driverRating,
    this.driverRatingCount = 0,
    this.offersFreeWifi = false,
    this.isFollowedDriver = false,
  });

  double? get minPrice => dropoffs.isEmpty
      ? null
      : dropoffs.map((d) => d.price).reduce((a, b) => a < b ? a : b);

  static List<RouteDropoff> _parseDropoffs(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(RouteDropoff.fromJson).toList();
  }

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
      dropoffs: _parseDropoffs(json['dropoffs']),
      minPassengers: (json['minPassengers'] as num?)?.toInt() ?? 1,
      totalAmountPaid: (json['totalAmountPaid'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'closed',
      offersFreeWifi: json['offersFreeWifi'] as bool? ?? false,
    );
  }

  /* --------------------------------------------------------------------------
   * BACKEND → APP (Passenger search DTO)
   * -------------------------------------------------------------------------- */
  factory Trip.fromSearchJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      driverId: '',
      driverName: json['driverName'] as String,
      from: json['route']['from'] as String,
      to: json['route']['to'] as String,
      date: DateTime.parse(json['date'] as String),
      departureWindow: (json['departureWindow'] as String?) ?? 'Unspecified',
      seatsTotal: json['seatsTotal'] as int,
      seatsAvailable: json['seatsAvailable'] as int,
      dropoffs: _parseDropoffs(json['dropoffs']),
      minPassengers: (json['minPassengers'] as num?)?.toInt() ?? 1,
      status: 'open',
      driverProfileImageUrl: json['driverProfileImageUrl'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble(),
      driverRatingCount: (json['driverRatingCount'] as num?)?.toInt() ?? 0,
      offersFreeWifi: json['offersFreeWifi'] as bool? ?? false,
      isFollowedDriver: json['isFollowedDriver'] as bool? ?? false,
    );
  }

  /* --------------------------------------------------------------------------
   * APP → BACKEND
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
      'dropoffs': dropoffs.map((d) => d.toJson()).toList(),
      'status': status,
      'driverProfileImageUrl': driverProfileImageUrl,
    };
  }
}
