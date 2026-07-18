import 'package:go_router/go_router.dart';

/// Holds the live GoRouter so that non-widget code (e.g. the FCM notification
/// handler in AuthNotifier) can trigger navigation imperatively.
class AppNavigator {
  AppNavigator._();

  static GoRouter? _router;

  static void init(GoRouter router) => _router = router;

  /// Navigate to [path], replacing the current stack.
  static void go(String path) => _router?.go(path);

  /// Push [path] on top of the current stack.
  static void push(String path, {Object? extra}) => _router?.push(path, extra: extra);
}
