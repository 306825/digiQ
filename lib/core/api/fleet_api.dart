import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

class FleetApi {
  final Dio dio;
  FleetApi(this.dio);

  Future<void> inviteDriver(String identifier) async {
    await dio.post('/fleet/invite', data: {'identifier': identifier});
  }

  Future<List<dynamic>> getMyInvitations() async {
    final res = await dio.get('/fleet/invitations');
    return res.data as List<dynamic>;
  }

  Future<void> acceptInvitation(String invitationId) async {
    await dio.patch('/fleet/invitations/$invitationId/accept');
  }

  Future<void> declineInvitation(String invitationId) async {
    await dio.patch('/fleet/invitations/$invitationId/decline');
  }

  Future<List<dynamic>> getFleetMembers() async {
    final res = await dio.get('/fleet/members');
    return res.data as List<dynamic>;
  }

  Future<void> removeMember(String driverId) async {
    await dio.delete('/fleet/members/$driverId');
  }
}

final fleetApiProvider = Provider<FleetApi>((ref) {
  return FleetApi(ref.read(apiClientProvider).dio);
});
