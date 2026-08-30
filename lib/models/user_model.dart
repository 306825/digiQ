import 'package:digiQ/models/driver_profile_model.dart';
import 'package:flutter/material.dart';

enum UserRole { passenger, driver, admin, fleetOwner }

enum DriverVerificationStatus { none, pending, approved, rejected }

enum PassengerVerificationStatus { none, pending, approved, rejected }

enum VehicleVerificationStatus { pending, approved, rejected, none }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final DriverVerificationStatus verificationStatus;
  final PassengerVerificationStatus passengerVerificationStatus;
  final bool? isActive;
  final DriverProfile? driverProfile;
  final String? profileImageUrl;
  final VehicleVerificationStatus vehicleStatus;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.verificationStatus,
    this.passengerVerificationStatus = PassengerVerificationStatus.none,
    this.isActive = true,
    this.profileImageUrl,
    this.driverProfile,
    required this.email,
    required this.vehicleStatus,
  });

  bool get isDriver => role == UserRole.driver;
  bool get isDriverVerified =>
      verificationStatus == DriverVerificationStatus.approved;
  bool get isVerificationPending =>
      verificationStatus == DriverVerificationStatus.none;
  bool get isPassengerVerified =>
      passengerVerificationStatus == PassengerVerificationStatus.approved;

  UserModel copyWith({
    String? id,
    String? fullName,
    UserRole? role,
    DriverVerificationStatus? verificationStatus,
    PassengerVerificationStatus? passengerVerificationStatus,
    bool? isActive,
    String? profileImageUrl,
  }) {
    return UserModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        role: role ?? this.role,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        passengerVerificationStatus:
            passengerVerificationStatus ?? this.passengerVerificationStatus,
        isActive: isActive ?? this.isActive,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        email: email,
        vehicleStatus: vehicleStatus);
  }

  /* --------------------------------------------------------------------------
   * JSON serialization
   * -------------------------------------------------------------------------- */

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      fullName: (json['fullName'] as String?) ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      role: _parseUserRole(json['role']),
      verificationStatus: _parseVerificationStatus(json['verificationStatus']),
      passengerVerificationStatus:
          _parsePassengerVerificationStatus(json['passengerVerificationStatus']),
      isActive: json['isActive'] as bool? ?? true,
      driverProfile: json['driverProfile'] != null
          ? DriverProfile.fromJson(json['driverProfile'])
          : null,
      email: json['identifier'],
      profileImageUrl: json['profileImageUrl'] as String?,
      vehicleStatus: _parseVehicleStatus(json['vehicleStatus']),
    );
  }

  static VehicleVerificationStatus _parseVehicleStatus(dynamic value) {
    if (value == null) return VehicleVerificationStatus.none;
    switch (value.toString().toLowerCase()) {
      case 'approved':
        return VehicleVerificationStatus.approved;
      case 'pending':
        return VehicleVerificationStatus.pending;
      case 'rejected':
        return VehicleVerificationStatus.rejected;
      default:
        return VehicleVerificationStatus.none;
    }
  }

  static UserRole _parseUserRole(dynamic value) {
    if (value == null) return UserRole.passenger;
    switch (value.toString().toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      case 'passenger':
        return UserRole.passenger;
      case 'fleet_owner':
        return UserRole.fleetOwner;
      default:
        debugPrint('⚠️ Unknown user role: $value');
        return UserRole.passenger;
    }
  }

  static DriverVerificationStatus _parseVerificationStatus(dynamic value) {
    if (value == null) return DriverVerificationStatus.none;
    switch (value.toString().toLowerCase()) {
      case 'approved':
        return DriverVerificationStatus.approved;
      case 'pending':
        return DriverVerificationStatus.pending;
      case 'rejected':
        return DriverVerificationStatus.rejected;
      default:
        return DriverVerificationStatus.none;
    }
  }

  static PassengerVerificationStatus _parsePassengerVerificationStatus(
      dynamic value) {
    if (value == null) return PassengerVerificationStatus.none;
    switch (value.toString().toLowerCase()) {
      case 'approved':
        return PassengerVerificationStatus.approved;
      case 'pending':
        return PassengerVerificationStatus.pending;
      case 'rejected':
        return PassengerVerificationStatus.rejected;
      default:
        return PassengerVerificationStatus.none;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': email,
      'fullName': fullName,
      'role': role.name,
      'verificationStatus': verificationStatus.name,
      'passengerVerificationStatus': passengerVerificationStatus.name,
      'vehicleStatus': vehicleStatus.name,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      if (driverProfile != null) 'driverProfile': driverProfile!.toJson(),
    };
  }
}
