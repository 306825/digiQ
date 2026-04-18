import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_providers.dart';
import '../models/user_model.dart';

class AdminDriversNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    debugPrint('🔥 ADMIN DRIVERS PROVIDER BUILD CALLED');

    final api = ref.read(adminApiProvider);
    debugPrint("TOKEN HEADER = ${api.dio.options.headers['Authorization']}");
    final response = await api.getDrivers();
    debugPrint(response.data.toString());
    debugPrint('RAW RESPONSE: ${response.data}');
    final List list = response.data;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> deactivate(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.deactivateDriver(driverId);
    await refresh();
  }

  Future<void> activate(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.activateDriver(driverId);
    await refresh();
  }

  Future<void> approve(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.approveDriver(driverId);
    await refresh();
  }

  Future<void> reject(String driverId) async {
    final api = ref.read(adminApiProvider);
    await api.rejectDriver(driverId);
    await refresh();
  }
}

final adminDriversProvider =
    AsyncNotifierProvider<AdminDriversNotifier, List<UserModel>>(
  AdminDriversNotifier.new,
);
