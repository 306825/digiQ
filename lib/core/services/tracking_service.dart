import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TrackingService {
  IO.Socket? socket;
  static const _storage = FlutterSecureStorage();

  Future<void> connect(String baseUrl) async {
    if (socket != null && socket!.connected) return;

    final token = await _storage.read(key: 'auth_token') ?? '';

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {});
    socket!.onDisconnect((_) {});
    socket!.onError((_) {});
    socket!.onConnectError((_) {});
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
