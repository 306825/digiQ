import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const _channelId = 'digiq_high';
const _channelName = 'digiQ Notifications';
const _channelDesc = 'Trip and booking updates from digiQ';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Listeners are registered once for the lifetime of the app.
  static bool _listenersRegistered = false;
  // Updated each login so the latest Riverpod ref gets the refresh calls.
  static void Function(RemoteMessage)? _onNotification;
  // Called only when the user taps a notification (background or terminated).
  static void Function(RemoteMessage)? _onTap;

  Future<void> init({
    required Future<void> Function(String token) onTokenReceived,
    void Function(RemoteMessage message)? onNotification,
    void Function(RemoteMessage message)? onTap,
  }) async {
    _onNotification = onNotification;
    _onTap = onTap;

    await _initLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );
    }

    final token = await _messaging.getToken();
    if (token != null) await onTokenReceived(token);

    _messaging.onTokenRefresh.listen((newToken) async {
      await onTokenReceived(newToken);
    });

    if (!_listenersRegistered) {
      _listenersRegistered = true;

      // App in foreground — show a local notification banner and refresh data.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: _channelDesc,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
        _onNotification?.call(message);
      });

      // User tapped a notification while app was in background → navigate.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _onNotification?.call(message);
        _onTap?.call(message);
      });
    }

    // App was fully terminated and opened via a notification tap.
    // Delay so the router has time to settle after auth restoration.
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        Future.delayed(const Duration(seconds: 2), () {
          _onNotification?.call(message);
          _onTap?.call(message);
        });
      }
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> deleteToken() => _messaging.deleteToken();
}

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _localNotifications.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // System tray handles display automatically on Android.
}
