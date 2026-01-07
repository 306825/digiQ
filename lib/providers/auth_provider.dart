import 'dart:convert';

import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  authenticating,
  authenticated,
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final UserModel? user;

  const AuthState({
    required this.status,
    this.token,
    this.user,
  });

  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initializing);
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  @override
  AuthState build() {
    _bootstrapAuth();
    //return const AuthState(status: AuthStatus.initializing);
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  /* --------------------------------------------------------------------------
   * Restore persisted auth
   * -------------------------------------------------------------------------- */

  Future<void> _bootstrapAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final api = ref.read(apiClientProvider);

      api.dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await api.dio.get('/auth/me');

      final user = UserModel.fromJson(response.data);

      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (_) {
      // token invalid / expired
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);

      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /* --------------------------------------------------------------------------
   * Login
   * -------------------------------------------------------------------------- */

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.authenticating);

    final api = ref.read(apiClientProvider);

    final response = await api.dio.post(
      '/auth/login',
      data: {
        'identifier': identifier,
        'password': password,
      },
    );

    final token = response.data['token'];
    final user = UserModel.fromJson(response.data['user']);

    api.dio.options.headers['Authorization'] = 'Bearer $token';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      user: user,
    );
  }

  /* --------------------------------------------------------------------------
   * Driver verification
   * -------------------------------------------------------------------------- */

  void submitDriverVerification() async {
    final user = state.user;
    if (user == null) return;

    final updated = user.copyWith(
      verificationStatus: DriverVerificationStatus.pending,
    );

    await _persistUser(updated);

    state = AuthState(
      status: state.status,
      token: state.token,
      user: updated,
    );
  }

  void approveDriverVerification() async {
    final user = state.user;
    if (user == null) return;

    final updated = user.copyWith(
      verificationStatus: DriverVerificationStatus.approved,
    );

    await _persistUser(updated);

    state = AuthState(
      status: state.status,
      token: state.token,
      user: updated,
    );
  }

  void rejectDriverVerification() async {
    final user = state.user;
    if (user == null) return;

    final updated = user.copyWith(
      verificationStatus: DriverVerificationStatus.rejected,
    );

    await _persistUser(updated);

    state = AuthState(
      status: state.status,
      token: state.token,
      user: updated,
    );
  }

  /* --------------------------------------------------------------------------
   * Logout
   * -------------------------------------------------------------------------- */

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /* --------------------------------------------------------------------------
   * Helpers
   * -------------------------------------------------------------------------- */

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
