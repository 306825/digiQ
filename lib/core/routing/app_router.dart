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

      final isLoggingIn = location == '/login';

      // 1️⃣ NOT AUTHENTICATED → ALWAYS LOGIN
      if (status != AuthStatus.authenticated) {
        return isLoggingIn ? null : '/login';
      }

      // 2️⃣ AUTHENTICATED BUT USER NOT READY (edge safety)
      if (user == null) {
        return '/login';
      }

      // 3️⃣ DRIVER FLOW
      if (user.role == UserRole.driver) {
        // Needs verification
        if (!user.isDriverVerified) {
          return location == '/driver/verify' ? null : '/driver/verify';
        }

        // Verified driver
        if (location == '/login' || location == '/driver/verify') {
          return '/driver/home';
        }

        return null;
      }

      // 4️⃣ PASSENGER FLOW
      if (user.role == UserRole.passenger) {
        if (isLoggingIn) {
          return '/passenger';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/passenger',
        builder: (context, state) => const PassengerHomeScreen(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/driver/verify',
        builder: (context, state) => const DriverVerificationScreen(),
      ),
    ],
  );
});
