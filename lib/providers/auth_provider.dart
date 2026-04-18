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
    _bootstrapAuthOnce();
    return const AuthState(status: AuthStatus.initializing);
  }

  bool _bootstrapped = false;

  Future<void> _bootstrapAuthOnce() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    await _bootstrapAuth();
  }

  /* --------------------------------------------------------------------------
   * Restore persisted auth
   * -------------------------------------------------------------------------- */

  Future<void> _bootstrapAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final cachedUserJson = prefs.getString(_userKey);

    if (token == null || cachedUserJson == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final user = UserModel.fromJson(jsonDecode(cachedUserJson));

      final api = ref.read(apiClientProvider);
      api.dio.options.headers['Authorization'] = 'Bearer $token';

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );

      //await refreshMe();
      // Optional: background refresh (NO state loop risk)
      //Future.microtask(() => refreshMe());
    } catch (_) {
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
      ).timeout(
        const Duration(seconds: 10),
      );

      debugPrint("🟢 RESPONSE RECEIVED: ${response.data}");

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

      //print("🚀 CALLING refreshMe()");
      //await refreshMe(); // ✅ THIS LINE IS MISSING
    } on DioException catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);

      print("❌ LOGIN ERROR STATUS: ${e.response?.statusCode}");
      print("❌ LOGIN ERROR DATA: ${e.response?.data}");
      final data = e.response?.data;

      if (data is Map && data['code'] == 'EMAIL_NOT_VERIFIED') {
        throw Exception('EMAIL_NOT_VERIFIED');
      }

      throw Exception('INVALID_CREDENTIALS');
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
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  }) async {
    state = const AuthState(status: AuthStatus.authenticating);

    try {
      final api = ref.read(apiClientProvider);

      await api.dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'identifier': identifier,
          'password': password,
          'role': role.name,
          'acceptedTerms': acceptedTerms,
          'acceptedPrivacy': acceptedPrivacy,
        },
      );

      // ✅ Do NOT login automatically
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      // debugPrint("LOGIN FAILED: $e");
      if (e is DioException) {
        debugPrint("REGISTER ERROR: ${e.response?.data}");
      }
      rethrow;
    }
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

  Future<void> refreshMe() async {
    final token = state.token;
    if (token == null) return;

    final api = ref.read(apiClientProvider);
    api.dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await api.dio.get('/auth/me');
      print("✅ API SUCCESS: $response");
      final user = UserModel.fromJson(response.data);
      // state = AuthState(
      //   status: AuthStatus.authenticated,
      //   token: token,
      //   user: user,
      // );
      final currentUser = state.user;

      if (currentUser != null &&
          currentUser.id == user.id &&
          currentUser.fullName == user.fullName &&
          currentUser.verificationStatus == user.verificationStatus) {
        // 🔒 NO CHANGE → DO NOTHING
        return;
      }

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );
    } catch (e) {
      if (e is DioException) {
        print("❌ API ERROR STATUS: ${e.response?.statusCode}");
        print("❌ API ERROR DATA: ${e.response?.data}");
      } else {
        print("❌ API ERROR: $e");
      }
    }
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
