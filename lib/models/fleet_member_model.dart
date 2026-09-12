class FleetVehicle {
  final String id;
  final String? make;
  final String? model;
  final String registrationNumber;
  final int seats;
  final String status;

  const FleetVehicle({
    required this.id,
    this.make,
    this.model,
    required this.registrationNumber,
    required this.seats,
    required this.status,
  });

  String get displayName =>
      '${make ?? ''} ${model ?? ''} • $registrationNumber'.trim();

  factory FleetVehicle.fromJson(Map<String, dynamic> json) => FleetVehicle(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        make: json['make'] as String?,
        model: json['model'] as String?,
        registrationNumber: json['registrationNumber'] as String? ?? '',
        seats: (json['seats'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'pending',
      );
}

class FleetEarnings {
  final double balance;
  final double totalEarned;
  final double totalPaidOut;

  const FleetEarnings({
    required this.balance,
    required this.totalEarned,
    required this.totalPaidOut,
  });

  factory FleetEarnings.fromJson(Map<String, dynamic> json) => FleetEarnings(
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
        totalPaidOut: (json['totalPaidOut'] as num?)?.toDouble() ?? 0,
      );
}

class FleetRecentTrip {
  final String id;
  final DateTime date;
  final String status;
  final String fromLabel;
  final String toLabel;
  final List<({String label, double price})> dropoffs;
  final int seatsTotal;
  final int seatsAvailable;

  const FleetRecentTrip({
    required this.id,
    required this.date,
    required this.status,
    required this.fromLabel,
    required this.toLabel,
    required this.dropoffs,
    required this.seatsTotal,
    required this.seatsAvailable,
  });

  double? get minPrice => dropoffs.isEmpty
      ? null
      : dropoffs.map((d) => d.price).reduce((a, b) => a < b ? a : b);

  factory FleetRecentTrip.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>? ?? {};
    final rawDropoffs = json['dropoffs'];
    final dropoffs = rawDropoffs is List
        ? rawDropoffs
            .whereType<Map<String, dynamic>>()
            .map((d) => (
                  label: d['label']?.toString() ?? '',
                  price: (d['price'] as num?)?.toDouble() ?? 0,
                ))
            .toList()
        : <({String label, double price})>[];
    return FleetRecentTrip(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? '',
      fromLabel: route['fromLabel'] as String? ?? '',
      toLabel: route['toLabel'] as String? ?? '',
      dropoffs: dropoffs,
      seatsTotal: (json['seatsTotal'] as num?)?.toInt() ?? 0,
      seatsAvailable: (json['seatsAvailable'] as num?)?.toInt() ?? 0,
    );
  }
}

class FleetMember {
  final String membershipId;
  final DateTime? joinedAt;
  final String driverId;
  final String driverName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String verificationStatus;
  final List<FleetVehicle> vehicles;
  final FleetEarnings earnings;
  final List<FleetRecentTrip> recentTrips;

  const FleetMember({
    required this.membershipId,
    this.joinedAt,
    required this.driverId,
    required this.driverName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.verificationStatus,
    required this.vehicles,
    required this.earnings,
    required this.recentTrips,
  });

  factory FleetMember.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>? ?? {};
    return FleetMember(
      membershipId: json['membershipId']?.toString() ?? '',
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
      driverId: driver['id']?.toString() ?? driver['_id']?.toString() ?? '',
      driverName: driver['fullName'] as String? ?? 'Unknown',
      phoneNumber: driver['phoneNumber'] as String?,
      profileImageUrl: driver['profileImageUrl'] as String?,
      verificationStatus: driver['verificationStatus'] as String? ?? 'none',
      vehicles: (json['vehicles'] as List<dynamic>? ?? [])
          .map((v) => FleetVehicle.fromJson(v as Map<String, dynamic>))
          .toList(),
      earnings: FleetEarnings.fromJson(
          json['earnings'] as Map<String, dynamic>? ?? {}),
      recentTrips: (json['recentTrips'] as List<dynamic>? ?? [])
          .map((t) => FleetRecentTrip.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
