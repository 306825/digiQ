import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/driver_follows_api.dart';
import 'package:strut/models/driver_follow_model.dart';

/* --------------------------------------------------------------------------
 * Driver public profile — keyed by driver ID
 * -------------------------------------------------------------------------- */

final driverProfileProvider =
    FutureProvider.family<DriverPublicProfile, String>((ref, driverId) {
  return ref.read(driverFollowsApiProvider).publicProfile(driverId);
});

/* --------------------------------------------------------------------------
 * Following list — passenger's followed drivers
 * -------------------------------------------------------------------------- */

class FollowingNotifier extends AsyncNotifier<List<DriverCard>> {
  @override
  Future<List<DriverCard>> build() async {
    return ref.read(driverFollowsApiProvider).myFollowing();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(driverFollowsApiProvider).myFollowing(),
    );
  }

  Future<void> unfollow(String driverId) async {
    await ref.read(driverFollowsApiProvider).unfollow(driverId);
    state = AsyncData(
      (state.value ?? []).where((d) => d.id != driverId).toList(),
    );
  }
}

final followingProvider =
    AsyncNotifierProvider<FollowingNotifier, List<DriverCard>>(
  FollowingNotifier.new,
);
