import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/admin_routes_api.dart';
import '../models/route_model.dart';

class AdminRoutesNotifier extends AsyncNotifier<List<RouteModel>> {
  @override
  Future<List<RouteModel>> build() async {
    return _fetch();
  }

  Future<List<RouteModel>> _fetch() async {
    final api = ref.read(adminRoutesApiProvider);
    final response = await api.getRoutes();
    final list = response.data as List;
    return list.map((e) => RouteModel.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> createRoute(String from, String to, double price) async {
    final api = ref.read(adminRoutesApiProvider);
    await api.createRoute(from: from, to: to, price: price);
    await refresh();
  }
}

final adminRoutesProvider =
    AsyncNotifierProvider<AdminRoutesNotifier, List<RouteModel>>(
  AdminRoutesNotifier.new,
);
