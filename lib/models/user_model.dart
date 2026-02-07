import 'package:flutter/material.dart';

enum UserRole { passenger, driver, admin }

enum DriverVerificationStatus { none, pending, approved, rejected }

class UserModel {
  final String id;
  final String fullName;
  final UserRole role;
  final DriverVerificationStatus verificationStatus;
  final bool? isActive;

  // 🖼️ NEW
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.verificationStatus,
    this.isActive = true,
    this.profileImageUrl,
  });

  bool get isDriver => role == UserRole.driver;
  bool get isDriverVerified =>
      verificationStatus == DriverVerificationStatus.approved;
  bool get isVerificationPending =>
      verificationStatus == DriverVerificationStatus.pending;

  UserModel copyWith({
    String? id,
    String? fullName,
    UserRole? role,
    DriverVerificationStatus? verificationStatus,
    bool? isActive,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  /* --------------------------------------------------------------------------
   * JSON serialization
   * -------------------------------------------------------------------------- */

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String,
      fullName: json['fullName'] as String,
      role: _parseUserRole(json['role']),
      verificationStatus: _parseVerificationStatus(json['verificationStatus']),
      isActive: json['isActive'] as bool? ?? true,

      // 🖼️ SAFE OPTIONAL
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  static UserRole _parseUserRole(dynamic value) {
    if (value == null) return UserRole.passenger;

    final normalized = value.toString().toLowerCase();

    switch (normalized) {
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      case 'passenger':
        return UserRole.passenger;
      default:
        debugPrint('⚠️ Unknown user role: $value');
        return UserRole.passenger;
    }
  }

  static DriverVerificationStatus _parseVerificationStatus(dynamic value) {
    if (value == null) return DriverVerificationStatus.none;

    final normalized = value.toString().toLowerCase();

    switch (normalized) {
      case 'approved':
        return DriverVerificationStatus.approved;
      case 'pending':
        return DriverVerificationStatus.pending;
      case 'rejected':
        return DriverVerificationStatus.rejected;
      case 'none':
        return DriverVerificationStatus.none;
      default:
        debugPrint('⚠️ Unknown verification status: $value');
        return DriverVerificationStatus.none;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
    };
  }
}
