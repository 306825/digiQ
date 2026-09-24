class DriverUpcomingTrip {
  final String id;
  final String date;
  final String departureWindow;
  final String from;
  final String to;
  final int seatsAvailable;
  final int seatsTotal;

  const DriverUpcomingTrip({
    required this.id,
    required this.date,
    required this.departureWindow,
    required this.from,
    required this.to,
    required this.seatsAvailable,
    required this.seatsTotal,
  });

  factory DriverUpcomingTrip.fromJson(Map<String, dynamic> json) {
    return DriverUpcomingTrip(
      id: json['id'] as String,
      date: json['date'] as String,
      departureWindow: json['departureWindow'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      seatsAvailable: (json['seatsAvailable'] as num?)?.toInt() ?? 0,
      seatsTotal: (json['seatsTotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverCard {
  final String id;
  final String fullName;
  final String? profileImageUrl;
  final double? ratingAvg;
  final int ratingCount;
  final bool following;

  const DriverCard({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.ratingAvg,
    required this.ratingCount,
    required this.following,
  });

  factory DriverCard.fromJson(Map<String, dynamic> json) {
    return DriverCard(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      following: json['following'] as bool? ?? false,
    );
  }

  DriverCard copyWith({bool? following}) {
    return DriverCard(
      id: id,
      fullName: fullName,
      profileImageUrl: profileImageUrl,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      following: following ?? this.following,
    );
  }
}

class DriverPublicProfile extends DriverCard {
  final int followerCount;

  const DriverPublicProfile({
    required super.id,
    required super.fullName,
    super.profileImageUrl,
    super.ratingAvg,
    required super.ratingCount,
    required super.following,
    required this.followerCount,
  });

  factory DriverPublicProfile.fromJson(Map<String, dynamic> json) {
    return DriverPublicProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      following: json['following'] as bool? ?? false,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  DriverPublicProfile copyWith({bool? following}) {
    return DriverPublicProfile(
      id: id,
      fullName: fullName,
      profileImageUrl: profileImageUrl,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      following: following ?? this.following,
      followerCount: followerCount,
    );
  }
}
