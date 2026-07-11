import 'dart:convert';

import 'package:digiQ/core/api/api_providers.dart';
import 'package:digiQ/core/api/user_api.dart';
import 'package:digiQ/providers/passenger_bookings_provider.dart';
import 'package:digiQ/services/fcm_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const _storage = FlutterSecureStorage();

  // @override
  // AuthState build() {
  //   _bootstrapAuthOnce();
  //   return const AuthState(status: AuthStatus.initializing);
  // }

  @override
  AuthState build() {
    // Kick off auth restoration; the router shows /splash until this resolves.
    Future.microtask(() async {
      try {
        await _bootstrapAuth();
      } catch (e) {
        // Any unhandled error during bootstrap must not leave the app stuck on
        // the splash screen. Fall back to unauthenticated so the user reaches
        // the login screen.
        print('[AUTH] Bootstrap error: $e');
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
    return const AuthState(status: AuthStatus.initializing);
  }

  Future<void> initialize() async {
    await _bootstrapAuth();
  }

  /* --------------------------------------------------------------------------
   * Restore persisted auth
   * -------------------------------------------------------------------------- */

  Future<void> _bootstrapAuth() async {
    // Run auth check and a minimum splash delay in parallel so the
    // splash is always visible long enough for the animation to play.
    final results = await Future.wait([
      _resolveAuthState(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);

    state = results[0] as AuthState;
  }

  Future<AuthState> _resolveAuthState() async {
    try {
      // flutter_secure_storage can throw on iOS if Keychain is temporarily
      // unavailable (e.g. first boot before first unlock). Timeout after 5 s
      // so a Keychain hang doesn't leave the splash screen stuck forever.
      final token = await _storage
          .read(key: _tokenKey)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      final cachedUserJson = await _storage
          .read(key: _userKey)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      if (token == null || cachedUserJson == null) {
        return const AuthState(status: AuthStatus.unauthenticated);
      }

      final user = UserModel.fromJson(jsonDecode(cachedUserJson));
      final api = ref.read(apiClientProvider);
      api.dio.options.headers['Authorization'] = 'Bearer $token';
      _registerFcmToken();
      return AuthState(status: AuthStatus.authenticated, token: token, user: user);
    } catch (_) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void _registerFcmToken() {
    final userApi = ref.read(userApiProvider);
    final fcm = FcmService();
    fcm.init(
      onTokenReceived: (token) async {
        try {
          await userApi.registerFcmToken(token);
        } catch (_) {}
      },
      onNotification: (RemoteMessage message) {
        // Refresh passenger bookings on any booking-related notification
        // so the UI updates without requiring a manual pull-to-refresh.
        final type = message.data['type'] as String? ?? '';
        if (type == 'booking_approved' ||
            type == 'booking_rejected' ||
            type == 'pickup_next' ||
            type == 'trip_started' ||
            type == 'trip_completed' ||
            type == 'trip_cancelled') {
          ref.invalidate(passengerBookingsProvider);
        }
      },
    ).catchError((_) {});
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

      final token = response.data['token'];
      final user = UserModel.fromJson(response.data['user']);

      api.dio.options.headers['Authorization'] = 'Bearer $token';

      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        user: user,
      );

      _registerFcmToken();
    } on DioException catch (e) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      );

      final data = e.response?.data;

      // Email not verified
      if (data is Map && data['code'] == 'EMAIL_NOT_VERIFIED') {
        throw Exception('EMAIL_NOT_VERIFIED');
      }

      // Invalid credentials
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('INVALID_CREDENTIALS');
      }

      // Ngrok/backend offline
      if (data.toString().contains('ERR_NGROK_3200')) {
        throw Exception('SERVER_OFFLINE');
      }

      // Timeout / no response
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('NETWORK_ERROR');
      }

      throw Exception('UNKNOWN_ERROR');
    }
  }

  /* --------------------------------------------------------------------------
   * Login
   * -------------------------------------------------------------------------- */

  Future<void> register({
    required String fullName,
    required String phoneNumber,
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
          'phoneNumber': phoneNumber,
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
      rethrow;
    }
  }

  /* --------------------------------------------------------------------------
   * Logout
   * -------------------------------------------------------------------------- */

  Future<void> logout() async {
    // Unregister FCM token before clearing credentials
    try {
      final fcm = FcmService();
      final token = await fcm.getToken();
      if (token != null) {
        await ref.read(userApiProvider).removeFcmToken(token);
      }
      await fcm.deleteToken();
    } catch (_) {}

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);

    // Clear cached data so the next login always fetches fresh state.
    ref.invalidate(passengerBookingsProvider);

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
    } catch (_) {}
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
