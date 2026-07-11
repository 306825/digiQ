class FleetInvitation {
  final String invitationId;
  final String fleetOwnerName;
  final String? fleetOwnerPhone;
  final String? fleetOwnerImageUrl;

  const FleetInvitation({
    required this.invitationId,
    required this.fleetOwnerName,
    this.fleetOwnerPhone,
    this.fleetOwnerImageUrl,
  });

  factory FleetInvitation.fromJson(Map<String, dynamic> json) {
    final owner = json['fleetOwner'] as Map<String, dynamic>? ?? {};
    return FleetInvitation(
      invitationId: json['invitationId']?.toString() ?? '',
      fleetOwnerName: owner['fullName'] as String? ?? 'Fleet Owner',
      fleetOwnerPhone: owner['phoneNumber'] as String?,
      fleetOwnerImageUrl: owner['profileImageUrl'] as String?,
    );
  }
}
