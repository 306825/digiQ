import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/trip_requests_api.dart';
import 'package:strut/models/trip_request_model.dart';

// Passenger: my requests
class MyTripRequestsNotifier extends AsyncNotifier<List<TripRequestModel>> {
  @override
  Future<List<TripRequestModel>> build() =>
      ref.read(tripRequestsApiProvider).mine();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<TripRequestModel> markDepositSent(String id) async {
    final updated = await ref.read(tripRequestsApiProvider).markDepositSent(id);
    state = AsyncData(state.value?.map((r) => r.id == id ? updated : r).toList() ?? []);
    return updated;
  }
}

final myTripRequestsProvider =
    AsyncNotifierProvider<MyTripRequestsNotifier, List<TripRequestModel>>(
        MyTripRequestsNotifier.new);

// Admin: all requests
class AdminTripRequestsNotifier extends AsyncNotifier<List<TripRequestModel>> {
  @override
  Future<List<TripRequestModel>> build() =>
      ref.read(tripRequestsApiProvider).adminList();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> confirmDeposit(String id) async {
    final updated = await ref.read(tripRequestsApiProvider).adminConfirmDeposit(id);
    state = AsyncData(state.value?.map((r) => r.id == id ? updated : r).toList() ?? []);
  }

  Future<void> linkTrip(String id, String tripId) async {
    final updated = await ref.read(tripRequestsApiProvider).adminLinkTrip(id, tripId);
    state = AsyncData(state.value?.map((r) => r.id == id ? updated : r).toList() ?? []);
  }
}

final adminTripRequestsProvider =
    AsyncNotifierProvider<AdminTripRequestsNotifier, List<TripRequestModel>>(
        AdminTripRequestsNotifier.new);
