import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class AppNotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.read,
    this.createdAt,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> j) =>
      AppNotificationItem(
        id: j['id'] as int,
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        type: j['type']?.toString() ?? 'GENERIC',
        data: j['data'] is Map
            ? Map<String, dynamic>.from(j['data'] as Map)
            : {},
        read: j['read'] == true,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );
}

class NotificationInboxService {
  NotificationInboxService._();
  static NotificationInboxService instance = NotificationInboxService._();

  static const _storage = FlutterSecureStorage();
  static const _cacheKey = 'rider_notification_cache_v1';

  final List<AppNotificationItem> _local = [];
  List<AppNotificationItem> get items => List.unmodifiable(_local);

  int get unreadCount => _local.where((n) => !n.read).length;

  Future<void> loadFromApi() async {
    final tok = await _storage.read(key: 'passenger_token');
    if (tok == null) return;

    try {
      final res = await http
          .get(
            Uri.parse('${Api.base}/notifications/me'),
            headers: {
              'Authorization': 'Bearer $tok',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = data is List ? data : [];
        _local
          ..clear()
          ..addAll(
            list.map(
              (e) => AppNotificationItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
        await _persistCache();
      }
    } catch (_) {}
  }

  Future<void> addFromPush({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> data = const {},
  }) async {
    _local.insert(
      0,
      AppNotificationItem(
        id: -DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        type: type,
        data: data,
        read: false,
        createdAt: DateTime.now(),
      ),
    );
    if (_local.length > 100) _local.removeRange(100, _local.length);
    await _persistCache();
    await loadFromApi();
  }

  Future<void> markRead(int id) async {
    final tok = await _storage.read(key: 'passenger_token');
    if (tok != null && id > 0) {
      try {
        await http.patch(
          Uri.parse('${Api.base}/notifications/me/$id/read'),
          headers: {'Authorization': 'Bearer $tok'},
        );
      } catch (_) {}
    }
    final i = _local.indexWhere((n) => n.id == id);
    if (i >= 0) {
      _local[i] = AppNotificationItem(
        id: _local[i].id,
        title: _local[i].title,
        body: _local[i].body,
        type: _local[i].type,
        data: _local[i].data,
        read: true,
        createdAt: _local[i].createdAt,
      );
    }
    await _persistCache();
  }

  Future<void> markAllRead() async {
    final tok = await _storage.read(key: 'passenger_token');
    if (tok != null) {
      try {
        await http.patch(
          Uri.parse('${Api.base}/notifications/me/read-all'),
          headers: {'Authorization': 'Bearer $tok'},
        );
      } catch (_) {}
    }
    await loadFromApi();
  }

  Future<void> loadCache() async {
    final raw = await _storage.read(key: _cacheKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _local
        ..clear()
        ..addAll(
          list.map(
            (e) => AppNotificationItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );
    } catch (_) {}
  }

  Future<void> _persistCache() async {
    final encoded = jsonEncode(
      _local
          .map(
            (n) => {
              'id': n.id,
              'title': n.title,
              'body': n.body,
              'type': n.type,
              'data': n.data,
              'read': n.read,
              'createdAt': n.createdAt?.toIso8601String(),
            },
          )
          .toList(),
    );
    await _storage.write(key: _cacheKey, value: encoded);
  }
}
