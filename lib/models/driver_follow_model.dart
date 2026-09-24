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
