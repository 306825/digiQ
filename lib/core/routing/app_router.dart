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

// appRouterProvider is kept alive because MyApp watches it via ref.watch.
// The ref.listen inside this provider therefore persists for the app lifetime,
// making auth → router refresh reliable without a separate notifier provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);

  // When auth status settles (initializing → authenticated/unauthenticated),
  // increment the notifier so GoRouter re-runs the redirect function.
  ref.listen<AuthState>(authProvider, (previous, next) {
    final prev = previous?.status;
    final curr = next.status;
    if (prev != curr &&
        (curr == AuthStatus.authenticated ||
            curr == AuthStatus.unauthenticated)) {
      notifier.value++;
    }
  });

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final user = authState.user;
      final location = state.matchedLocation;

      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isSignup = location == '/signup';
      final isForgotPassword = location == '/forgot-password';
      final isResetPassword = location.startsWith('/reset-password');
      final isTerms = location == '/terms';
      final isPrivacy = location == '/privacy';

      // Hold on /splash until auth resolves
      if (status == AuthStatus.initializing) {
        return isSplash ? null : '/splash';
      }

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

      if (status == AuthStatus.authenticating) {
        return isLogin ? null : '/login';
      }

      if (user == null) {
        return '/login';
      }

      final role = user.role;

      if (role == UserRole.admin) {
        if (isLogin || isSignup || isSplash) return '/admin';
        return null;
      }

      if (role == UserRole.driver) {
        final needsVerification =
            user.verificationStatus != DriverVerificationStatus.approved;

        if (needsVerification) {
          return location == '/driver/verify' ? null : '/driver/verify';
        }

        if (isLogin || isSplash) {
          return '/driver/home';
        }

        return null;
      }

      if (role == UserRole.passenger) {
        if (isLogin || isSplash) return '/passenger';
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
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
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
