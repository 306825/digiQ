import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/routes_api.dart';
import '../models/route_model.dart';

class RoutesNotifier extends AsyncNotifier<List<RouteModel>> {
  @override
  Future<List<RouteModel>> build() async {
    final api = ref.read(routesApiProvider);
    final response = await api.getRoutes();
    final list = response.data as List;
    return list.map((e) => RouteModel.fromJson(e)).toList();
  }
}

final routesProvider = AsyncNotifierProvider<RoutesNotifier, List<RouteModel>>(
  RoutesNotifier.new,
);
