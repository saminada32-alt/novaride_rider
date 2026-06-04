import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class RiderSocketService {
  RiderSocketService._();
  static RiderSocketService instance = RiderSocketService._();

  IO.Socket? _socket;
  static const _storage = FlutterSecureStorage();

  int? _pendingTripId;

  Function(Map<String, dynamic>)? onTripEvent;
  Function(double lat, double lng)? onDriverMoved;
  Function(Map<String, dynamic>)? onChatMessage;
  Function(Map<String, dynamic>)? onSupportChatMessage;

  Future<void> connect() async {
    final tok = await _storage.read(key: 'passenger_token');
    if (tok == null) return;

    if (_socket?.connected == true) return;

    _socket = IO.io(
      '${Api.base}/tracking',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': tok})
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Rider Socket Connected');
      if (_pendingTripId != null) {
        _socket!.emit('trip:join', {'tripId': _pendingTripId});
        _pendingTripId = null;
      }
    });

    _socket!.on('ride_assigned', (data) {
      onTripEvent?.call(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('ride_status_changed', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      onTripEvent?.call({'_type': 'status_change', ...payload});
    });

    _socket!.on('ride_cancelled', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      onTripEvent?.call({
        '_type': 'status_change',
        'status': 'CANCELLED',
        ...payload,
      });
    });

    _socket!.on('ride_update', (data) {
      final payload = Map<String, dynamic>.from(data as Map);
      onTripEvent?.call({
        '_type': 'status_change',
        'status': payload['status']?.toString().toUpperCase() ?? 'SEARCHING',
        'id': payload['rideId'],
        'rideId': payload['rideId'],
      });
    });

    _socket!.on('chat:message', (data) {
      onChatMessage?.call(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('support_chat:message', (data) {
      onSupportChatMessage?.call(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('driver:moved', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      onDriverMoved?.call(
        (d['lat'] as num).toDouble(),
        (d['lng'] as num).toDouble(),
      );
    });

    _socket!.connect();
  }

  void joinTrip(int tripId) {
    if (_socket?.connected == true) {
      _socket!.emit('trip:join', {'tripId': tripId});
    } else {
      _pendingTripId = tripId;
    }
  }

  void leaveTrip(int tripId) {
    _socket?.emit('trip:leave', {'tripId': tripId});
  }

  void disconnect() => _socket?.disconnect();
}
