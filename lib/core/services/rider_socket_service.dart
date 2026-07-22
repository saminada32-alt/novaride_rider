import 'package:flutter/foundation.dart';
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

  void _safe(String event, void Function() fn) {
    try {
      fn();
    } catch (e) {
      if (kDebugMode) debugPrint('Rider socket $event: $e');
    }
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

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
      if (kDebugMode) debugPrint('Rider Socket Connected');
      if (_pendingTripId != null) {
        _socket!.emit('trip:join', {'tripId': _pendingTripId});
        _pendingTripId = null;
      }
    });

    _socket!.on('ride_assigned', (data) {
      _safe('ride_assigned', () {
        final map = _asMap(data);
        if (map == null) return;
        onTripEvent?.call(map);
      });
    });

    _socket!.on('ride_status_changed', (data) {
      _safe('ride_status_changed', () {
        final payload = _asMap(data);
        if (payload == null) return;
        onTripEvent?.call({'_type': 'status_change', ...payload});
      });
    });

    _socket!.on('ride_cancelled', (data) {
      _safe('ride_cancelled', () {
        final payload = _asMap(data);
        if (payload == null) return;
        onTripEvent?.call({
          '_type': 'status_change',
          'status': 'CANCELLED',
          ...payload,
        });
      });
    });

    _socket!.on('ride_update', (data) {
      _safe('ride_update', () {
        final payload = _asMap(data);
        if (payload == null) return;
        onTripEvent?.call({
          '_type': 'status_change',
          'status': payload['status']?.toString().toUpperCase() ?? 'SEARCHING',
          'id': payload['rideId'],
          'rideId': payload['rideId'],
        });
      });
    });

    _socket!.on('chat:message', (data) {
      _safe('chat:message', () {
        final map = _asMap(data);
        if (map == null) return;
        onChatMessage?.call(map);
      });
    });

    _socket!.on('support_chat:message', (data) {
      _safe('support_chat:message', () {
        final map = _asMap(data);
        if (map == null) return;
        onSupportChatMessage?.call(map);
      });
    });

    _socket!.on('driver:moved', (data) {
      _safe('driver:moved', () {
        final d = _asMap(data);
        if (d == null) return;
        final lat = d['lat'];
        final lng = d['lng'];
        if (lat is! num || lng is! num) return;
        onDriverMoved?.call(lat.toDouble(), lng.toDouble());
      });
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
