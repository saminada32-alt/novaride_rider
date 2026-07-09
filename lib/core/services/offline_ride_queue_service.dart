import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/rider/models/ride_model.dart';
import '../../features/rider/services/rider_service.dart';

class QueuedRideRequest {
  final String id;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  bool get isScheduled =>
      payload['scheduledAt'] != null &&
      payload['scheduledAt'].toString().isNotEmpty;

  QueuedRideRequest({
    required this.id,
    required this.payload,
    required this.createdAt,
  });

  factory QueuedRideRequest.fromJson(Map<String, dynamic> j) => QueuedRideRequest(
        id: j['id']?.toString() ?? '',
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };
}

class OfflineRideQueueService extends ChangeNotifier {
  OfflineRideQueueService._();
  static final instance = OfflineRideQueueService._();

  static const _key = 'offline_ride_queue_v1';
  static const _legacyPrefsKey = 'offline_ride_queue_v1';
  static const _storage = FlutterSecureStorage();

  List<QueuedRideRequest> _queue = [];
  bool _flushing = false;

  List<QueuedRideRequest> get pending => List.unmodifiable(_queue);
  int get count => _queue.length;
  bool get isFlushing => _flushing;

  Future<void> load() async {
    var raw = await _storage.read(key: _key);
    if (raw == null) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_legacyPrefsKey);
      if (raw != null) {
        await _storage.write(key: _key, value: raw);
        await prefs.remove(_legacyPrefsKey);
      }
    }
    if (raw == null) {
      _queue = [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _queue = list
          .map((e) => QueuedRideRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _queue = [];
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _key,
      value: jsonEncode(_queue.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> enqueue(Map<String, dynamic> createPayload) async {
    await load();
    _queue.add(QueuedRideRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      payload: createPayload,
      createdAt: DateTime.now(),
    ));
    await _persist();
  }

  int get scheduledCount =>
      _queue.where((q) => q.isScheduled).length;

  int get instantCount => _queue.length - scheduledCount;

  Future<RideModel?> flush({
    void Function(int remaining)? onProgress,
    void Function(int submitted)? onSubmitted,
  }) async {
    if (_flushing) return null;
    await load();
    if (_queue.isEmpty) return null;

    _flushing = true;
    notifyListeners();
    RideModel? lastRide;

    try {
      final actions = <Map<String, dynamic>>[];
      final validItems = <QueuedRideRequest>[];

      for (final item in _queue) {
        if (item.isScheduled) {
          final at = DateTime.tryParse(
            item.payload['scheduledAt']?.toString() ?? '',
          );
          if (at != null &&
              at.isBefore(DateTime.now().add(const Duration(minutes: 25)))) {
            continue;
          }
        }
        validItems.add(item);
        actions.add({
          'clientId': item.id,
          'type': 'create_ride',
          'payload': item.payload,
        });
      }

      if (actions.isNotEmpty) {
        try {
          final result = await RiderService.instance.syncOfflineActions(actions);
          final results = result['results'] as List<dynamic>? ?? [];
          final succeeded = results
              .where((r) => r is Map && r['success'] == true)
              .map((r) => (r as Map)['clientId']?.toString())
              .whereType<String>()
              .toSet();

          _queue.removeWhere((q) => succeeded.contains(q.id));
          await _persist();
          onProgress?.call(_queue.length);
          onSubmitted?.call(succeeded.length);

          for (final r in results) {
            if (r is Map && r['ride'] is Map) {
              lastRide = RideModel.fromJson(
                Map<String, dynamic>.from(r['ride'] as Map),
              );
            }
          }
        } catch (e) {
          if (_isNetworkError(e)) {
            // Fallback: submit one-by-one
            for (final item in List<QueuedRideRequest>.from(_queue)) {
              try {
                lastRide = await RiderService.instance.createRideFromPayload(
                  item.payload,
                );
                _queue.removeWhere((q) => q.id == item.id);
                await _persist();
                onProgress?.call(_queue.length);
                onSubmitted?.call(1);
              } catch (err) {
                if (_isNetworkError(err)) break;
                _queue.removeWhere((q) => q.id == item.id);
                await _persist();
              }
            }
          }
        }
      }
    } finally {
      _flushing = false;
      notifyListeners();
    }
    return lastRide;
  }

  static bool _isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('failed host') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('clientexception');
  }
}
