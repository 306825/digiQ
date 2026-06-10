import 'package:digiQ/features/admin/admin_home_screen.dart';
import 'package:digiQ/features/admin/admin_incidents_screen.dart';
import 'package:digiQ/features/admin/widgets/admin_routes_tab.dart';
import 'package:digiQ/features/auth/account_deactivated_screen.dart';
import 'package:digiQ/features/auth/forgot_password_screen.dart';
import 'package:digiQ/features/auth/login_screen.dart';
import 'package:digiQ/features/auth/privacy_screen.dart';
import 'package:digiQ/features/auth/reset_password_screen.dart';
import 'package:digiQ/features/auth/signup_screen.dart';
import 'package:digiQ/features/auth/terms_screen.dart';
import 'package:digiQ/features/auth/verify_email.dart';
import 'package:digiQ/features/driver/driver_home_screen.dart';
import 'package:digiQ/features/driver/driver_vehicle_screen.dart';
import 'package:digiQ/features/driver/driver_verification_screen.dart';
import 'package:digiQ/features/passenger/booking_detaills_screen.dart';
import 'package:digiQ/features/passenger/passenger_home_screen.dart';
import 'package:digiQ/features/shared/screens/splash_screen.dart';
import 'package:digiQ/models/user_model.dart';
import 'package:digiQ/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// ✅ Notifier that tells GoRouter to refresh when auth changes
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      final prev = previous?.status;
      final curr = next.status;

      final shouldRefresh = prev != curr &&
          (curr == AuthStatus.authenticated ||
              curr == AuthStatus.unauthenticated);

      if (shouldRefresh) {
        notifyListeners();
      }
    });
  }
}

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  //final refreshNotifier = RouterRefreshNotifier(ref);
  final refreshNotifier = ref.read(routerRefreshNotifierProvider);

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final user = authState.user;
      final location = state.matchedLocation;

      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isForgotPassword = location == '/forgot-password';
      final isResetPassword = location.startsWith('/reset-password');
      final isTerms = location == '/terms';
      final isPrivacy = location == '/privacy';

      // 0️⃣ Bootstrapping — hold on /splash until auth resolves
      if (status == AuthStatus.initializing) {
        return location == '/splash' ? null : '/splash';
      }

      // 1️⃣ Not authenticated
      if (status == AuthStatus.unauthenticated) {
        if (isLogin ||
            isSignup ||
            isForgotPassword ||
            isResetPassword ||
            isTerms ||
            isPrivacy) {
          return null;
        }
        return '/login';
      }

      // 2️⃣ Auth settling
      // if (status == AuthStatus.authenticating || user == null) {
      //   return null;
      // }

      if (status == AuthStatus.authenticating) {
        return location == '/login' ? null : '/login';
      }

      if (user == null) {
        return '/login';
      }

      final role = user.role;

      // 🛡️ ADMIN
      if (role == UserRole.admin) {
        if (isLogin || isSignup) return '/admin';
        return null;
      }

      // 🚗 DRIVER
      if (role == UserRole.driver) {
        final needsVerification =
            user.verificationStatus != DriverVerificationStatus.approved;

        if (needsVerification) {
          return location == '/driver/verify' ? null : '/driver/verify';
        }

        if (location == '/login') {
          return '/driver/home';
        }

        return null;
      }

      // 🧍 PASSENGER
      if (role == UserRole.passenger) {
        if (isLogin) return '/passenger';
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/login'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/passenger', builder: (_, __) => const PassengerHomeScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
      GoRoute(path: '/driver/home', builder: (_, __) => DriverHomeScreen()),
      GoRoute(
          path: '/driver/verify',
          builder: (_, __) => DriverVerificationScreen()),
      GoRoute(
          path: '/admin/routes', builder: (_, __) => const AdminRoutesTab()),
      // GoRoute(
      //     path: '/admin/drivers',
      //     builder: (_, __) => const AdminDriversScreen()),
      GoRoute(
          path: '/deactivated',
          builder: (_, __) => const AccountDeactivatedScreen()),
      GoRoute(
          path: '/verify-email', builder: (_, __) => const VerifyEmailScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(resetToken: token);
        },
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return BookingDetailsScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/admin/incidents',
        builder: (_, __) => const AdminIncidentsScreen(),
      ),

      GoRoute(
        path: '/driver/vehicle',
        builder: (_, __) => const DriverVehicleScreen(),
      ),
    ],
  );
});
