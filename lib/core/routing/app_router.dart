import 'package:digiQ/features/auth/login_screen.dart';
import 'package:digiQ/features/driver/driver_home_screen.dart';
import 'package:digiQ/features/driver/driver_verification_screen.dart';
import 'package:digiQ/features/passenger/passenger_home_screen.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final status = authState.status;
      final user = authState.user;
      final location = state.matchedLocation;

      final isLogin = location == '/login';

      // 🟡 0. AUTH STILL INITIALIZING → DO NOTHING
      if (status == AuthStatus.initializing) {
        return null;
      }

      // 🔒 1. NOT AUTHENTICATED → FORCE LOGIN
      if (status == AuthStatus.unauthenticated) {
        return isLogin ? null : '/login';
      }

      // 🛑 Safety
      if (user == null) {
        return '/login';
      }

      // 🚗 2. DRIVER FLOW
      if (user.role == UserRole.driver) {
        if (!user.isDriverVerified) {
          return location == '/driver/verify' ? null : '/driver/verify';
        }

        if (isLogin || location == '/driver/verify') {
          return '/driver/home';
        }

        return null;
      }

      // 🧍 3. PASSENGER FLOW
      if (user.role == UserRole.passenger) {
        if (isLogin) {
          return '/passenger';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/passenger',
        builder: (_, __) => const PassengerHomeScreen(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (_, __) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/driver/verify',
        builder: (_, __) => const DriverVerificationScreen(),
      ),
    ],
  );
});
