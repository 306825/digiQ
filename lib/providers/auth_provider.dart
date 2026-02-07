import 'dart:convert';

import 'package:digiQ/core/api/api_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  @override
  AuthState build() {
    //SharedPreferences.getInstance().then((p) => p.clear());
    _bootstrapAuth();
    return const AuthState(status: AuthStatus.initializing);
  }

  /* --------------------------------------------------------------------------
   * Restore persisted auth
   * -------------------------------------------------------------------------- */

  Future<void> _bootstrapAuth() async {
    debugPrint('🧪 BOOTSTRAP START');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final cachedUserJson = prefs.getString(_userKey);

    debugPrint('🧪 BOOTSTRAP TOKEN = $token');
    debugPrint('🧪 CACHED USER JSON = $cachedUserJson');

    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    // ✅ Optimistically restore cached user immediately (prevents router flicker)
    UserModel? cachedUser;
    if (cachedUserJson != null) {
      try {
        cachedUser = UserModel.fromJson(jsonDecode(cachedUserJson));
      } catch (_) {
        cachedUser = null;
      }
    }

    if (cachedUser != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: cachedUser,
      );
    }

    try {
      final api = ref.read(apiClientProvider);
      api.dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await api.dio.get('/auth/me');
      debugPrint('🧪 RAW USER JSON = ${response.data}');

      final user = UserModel.fromJson(response.data);

      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (e) {
      debugPrint('❌ Bootstrap failed: $e');

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

    try {
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
    } on DioException catch (e) {
      debugPrint('❌ Login failed: ${e.response?.statusCode}');
      debugPrint('❌ Login error: ${e.response?.data}');

      // 🔄 Reset state so UI unlocks
      state = const AuthState(status: AuthStatus.unauthenticated);

      rethrow; // allow UI to react if needed
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');

      state = const AuthState(status: AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /* --------------------------------------------------------------------------
   * Login
   * -------------------------------------------------------------------------- */

  Future<void> register({
    required String fullName,
    required String identifier,
    required String password,
    required UserRole role,
  }) async {
    state = const AuthState(status: AuthStatus.authenticating);

    final api = ref.read(apiClientProvider);

    final response = await api.dio.post(
      '/auth/register',
      data: {
        'fullName': fullName,
        'identifier': identifier,
        'password': password,
        'role': role.name, // 'driver' or 'passenger'
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

  Future<void> refreshMe() async {
    final token = state.token;
    if (token == null) return;

    final api = ref.read(apiClientProvider);
    api.dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await api.dio.get('/auth/me');
    final user = UserModel.fromJson(response.data);

    state = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      user: user,
    );
  }

  Future<void> updateAvatar(String imageUrl) async {
    final current = state.user;
    if (current == null) return;

    state = state.copyWith(
      user: current.copyWith(profileImageUrl: imageUrl),
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
