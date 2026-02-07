import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/admin_api.dart';
import '../models/user_model.dart';

class AdminPendingDriversNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    final api = ref.read(adminApiProvider);
    final response = await api.getPendingDrivers();

    final List<dynamic> list = response.data;
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> approve(String userId) async {
    await ref.read(adminApiProvider).approveDriver(userId);
    await refresh();
  }

  Future<void> reject(String userId) async {
    await ref.read(adminApiProvider).rejectDriver(userId);
    await refresh();
  }
}

final adminPendingDriversProvider =
    AsyncNotifierProvider<AdminPendingDriversNotifier, List<UserModel>>(
        AdminPendingDriversNotifier.new);
