import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  IO.Socket? _socket;
  static const _storage = FlutterSecureStorage();

  // Await actual TCP/WS connection before returning so joinChat fires on a live socket
  Future<void> connect(String baseUrl) async {
    if (_socket != null && (_socket!.connected)) return;

    _socket?.dispose();
    _socket = null;

    final token = await _storage.read(key: 'auth_token') ?? '';

    _socket = IO.io(
      '$baseUrl/chat',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    final completer = Completer<void>();

    _socket!.onConnect((_) {
      debugPrint('[CHAT] Connected');
      if (!completer.isCompleted) completer.complete();
    });
    _socket!.onConnectError((err) {
      debugPrint('[CHAT] Connect error: $err');
      if (!completer.isCompleted) completer.completeError(err ?? 'connection error');
      _socket?.dispose();
      _socket = null;
    });
    _socket!.onDisconnect((_) => debugPrint('[CHAT] Disconnected'));

    _socket!.connect();

    // Wait up to 10 s for the socket to connect
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('[CHAT] Connection timed out'),
    );
  }

  void joinChat(String bookingId) {
    _socket?.emit('chat:join', bookingId);
  }

  void sendMessage(String bookingId, String text) {
    _socket?.emit('chat:send', {'bookingId': bookingId, 'text': text});
  }

  void onMessage(void Function(Map<String, dynamic> data) callback) {
    _socket?.off('chat:message');
    _socket?.on('chat:message', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
