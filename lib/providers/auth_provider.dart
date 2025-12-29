import 'package:flutter_riverpod/legacy.dart';

class AuthState {
  final bool isAuthenticated;
  final String? token;
  final bool isLoading;

  AuthState({
    required this.isAuthenticated,
    this.token,
    this.isLoading = false,
  });

  factory AuthState.initial() => AuthState(isAuthenticated: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  Future<void> login(String identifier, String password) async {
    state = AuthState(isAuthenticated: false, isLoading: true);

    // call API
    // final token = ...

    state = AuthState(isAuthenticated: true, token: "JWT_TOKEN");
  }

  void logout() {
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
