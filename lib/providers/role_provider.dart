import 'package:flutter_riverpod/legacy.dart';

enum AppRole { passenger, driver }

final roleProvider = StateProvider<AppRole>((ref) => AppRole.passenger);
