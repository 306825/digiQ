enum UserRole { passenger, driver }

enum DriverVerificationStatus { none, pending, approved, rejected }

class UserModel {
  final String id;
  final String fullName;
  final UserRole role;
  final DriverVerificationStatus verificationStatus;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.verificationStatus,
  });

  bool get isDriverVerified =>
      verificationStatus == DriverVerificationStatus.approved;

  UserModel copyWith({
    String? id,
    String? fullName,
    UserRole? role,
    DriverVerificationStatus? verificationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  /* --------------------------------------------------------------------------
   * JSON serialization (for persistence)
   * -------------------------------------------------------------------------- */

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      verificationStatus: DriverVerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
    };
  }
}
