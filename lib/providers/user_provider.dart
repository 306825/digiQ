import 'package:digiQ/models/user_model.dart';
import 'package:flutter_riverpod/legacy.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  void setUser(UserModel user) {
    state = user;
  }

  void clear() {
    state = null;
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel?>(
  (ref) => UserNotifier(),
);
