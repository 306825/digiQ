import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingService {
  IO.Socket? socket;
  static const _storage = FlutterSecureStorage();

  /// Initialises the socket and starts connecting. Returns once the socket
  /// object is ready (token is read, options are set). The actual TCP/polling
  /// handshake completes asynchronously — events emitted before it finishes
  /// are buffered by socket.io and flushed automatically on connect.
  Future<void> connect(String baseUrl) async {
    if (socket != null) return; // already initialised (connecting or connected)

    final token = await _storage.read(key: 'auth_token') ?? '';

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.onConnect((_) => debugPrint('[SOCKET] Connected'));
    socket!.onConnectError((err) {
      debugPrint('[SOCKET] Connect error: $err');
      // Reset so the next connect() call retries from scratch.
      socket?.dispose();
      socket = null;
    });
    socket!.onDisconnect((_) => debugPrint('[SOCKET] Disconnected'));

    socket!.connect();
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
    socket?.dispose();
    socket = null;
  }
}
