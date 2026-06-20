import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingService {
  IO.Socket? socket;
  static const _storage = FlutterSecureStorage();

  /// Connects to the WebSocket server and waits until the connection is
  /// actually established before returning. This ensures joinTrip() and
  /// listenToLocation() are called on a live socket.
  Future<void> connect(String baseUrl) async {
    if (socket != null && socket!.connected) return;

    final token = await _storage.read(key: 'auth_token') ?? '';

    final completer = Completer<void>();

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
    });

    socket!.onConnectError((err) {
      if (!completer.isCompleted) {
        completer.completeError(err ?? 'Connection failed');
      }
    });

    socket!.onDisconnect((_) {});
    socket!.onError((_) {});

    socket!.connect();

    // Await actual connection — throws if connection fails
    await completer.future;
  }

  void joinTrip(String tripId) {
    socket?.emit('join:trip', tripId);
  }

  void sendLocation(String tripId, double lat, double lng) {
    socket?.emit('location:update', {
      'tripId': tripId,
      'lat': lat,
      'lng': lng,
    });
  }

  void listenToLocation(Function(double lat, double lng) onUpdate) {
    socket?.off('location:update');
    socket?.on('location:update', (data) {
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      onUpdate(lat, lng);
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
