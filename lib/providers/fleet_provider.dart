import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/fleet_api.dart';
import '../models/fleet_member_model.dart';
import '../models/fleet_invitation_model.dart';

// ── Fleet members (fleet owner) ─────────────────────────────────────────────

class FleetMembersNotifier extends AsyncNotifier<List<FleetMember>> {
  @override
  Future<List<FleetMember>> build() => _fetch();

  Future<List<FleetMember>> _fetch() async {
    final data = await ref.read(fleetApiProvider).getFleetMembers();
    return data
        .map((j) => FleetMember.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> inviteDriver(String identifier) async {
    await ref.read(fleetApiProvider).inviteDriver(identifier);
  }

  Future<void> removeMember(String driverId) async {
    await ref.read(fleetApiProvider).removeMember(driverId);
    await refresh();
  }
}

final fleetMembersProvider =
    AsyncNotifierProvider<FleetMembersNotifier, List<FleetMember>>(
  FleetMembersNotifier.new,
);

// ── Fleet invitations (driver) ───────────────────────────────────────────────

class FleetInvitationsNotifier extends AsyncNotifier<List<FleetInvitation>> {
  @override
  Future<List<FleetInvitation>> build() => _fetch();

  Future<List<FleetInvitation>> _fetch() async {
    final data = await ref.read(fleetApiProvider).getMyInvitations();
    return data
        .map((j) => FleetInvitation.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> accept(String invitationId) async {
    await ref.read(fleetApiProvider).acceptInvitation(invitationId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> decline(String invitationId) async {
    await ref.read(fleetApiProvider).declineInvitation(invitationId);
    ref.invalidateSelf();
    await future;
  }
}

final fleetInvitationsProvider =
    AsyncNotifierProvider<FleetInvitationsNotifier, List<FleetInvitation>>(
  FleetInvitationsNotifier.new,
);
