import 'package:digiQ/features/admin/admin_drivers_screen.dart';
import 'package:digiQ/features/admin/admin_home_screen.dart';
import 'package:digiQ/features/admin/widgets/admin_routes_tab.dart';
import 'package:digiQ/features/auth/account_deactivated_screen.dart';
import 'package:digiQ/features/auth/login_screen.dart';
import 'package:digiQ/features/auth/signup_screen.dart';
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
      final isSignup = location == '/signup';

      // 0️⃣ Still bootstrapping
      if (status == AuthStatus.initializing) {
        return null;
      }

      // 1️⃣ Not authenticated
      if (status == AuthStatus.unauthenticated) {
        if (isLogin || isSignup) return null;
        return '/login';
      }

      // 2️⃣ Authenticated but user not hydrated yet (bootstrap race)
      if (status == AuthStatus.authenticated && user == null) {
        return null; // wait
      }

      // ✅ From here user is guaranteed non-null
      final role = user!.role;

      // 🛡️ ADMIN FLOW
      if (role == UserRole.admin) {
        if (isLogin || isSignup) return '/admin';
        return null;
      }

      // 🚗 DRIVER FLOW
      if (role == UserRole.driver) {
        final needsVerification =
            user.verificationStatus != DriverVerificationStatus.approved;

        if (needsVerification) {
          return location == '/driver/verify' ? null : '/driver/verify';
        }

        if (isLogin || location == '/driver/verify') {
          return '/driver/home';
        }

        return null;
      }

      // 🧍 PASSENGER FLOW
      if (role == UserRole.passenger) {
        if (isLogin) return '/passenger';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/passenger',
        builder: (_, __) => const PassengerHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (_, __) => DriverHomeScreen(),
      ),
      GoRoute(
        path: '/driver/verify',
        builder: (_, __) => DriverVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/routes',
        builder: (_, __) => const AdminRoutesTab(),
      ),
      GoRoute(
        path: '/admin/drivers',
        builder: (_, __) => const AdminDriversScreen(),
      ),
      GoRoute(
        path: '/deactivated',
        builder: (_, __) => const AccountDeactivatedScreen(),
      ),
    ],
  );
});
