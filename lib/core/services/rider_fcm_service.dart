import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../navigation/app_navigator.dart';
import 'notification_inbox_service.dart';
import '../../features/rider/account/familyprofile/familyprofile_screen.dart';
import '../../features/rider/split_fare/split_fare_invites_screen.dart';

class RiderFcmService {
  RiderFcmService._();
  static RiderFcmService instance = RiderFcmService._();

  final _storage = const FlutterSecureStorage();
  final _localNotif = FlutterLocalNotificationsPlugin();

  Function(String status, int rideId)? onRideUpdate;

  Future<void> init() async {
    try {
      await _localNotif.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          _handlePayload(payload);
        }
      },
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'novaride_rider',
            'NovaRide Updates',
            importance: Importance.high,
            playSound: true,
          ),
        );

    final msg = FirebaseMessaging.instance;
    await msg.requestPermission(alert: true, badge: true, sound: true);

    final token = await msg.getToken();
    if (token != null) await _upload(token);
    msg.onTokenRefresh.listen(_upload);

    FirebaseMessaging.onMessage.listen((m) {
      final title = m.notification?.title ?? 'NovaRide';
      final body = m.notification?.body ?? '';
      _recordInbox(title, body, m.data);
      _showLocalNotif(
        title,
        body,
        payload: jsonEncode(m.data),
      );
      _handleData(m.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleData(m.data));

    final initial = await msg.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleData(initial.data);
      });
    }
    } catch (e, st) {
      debugPrint('RiderFcmService init failed: $e');
    }
  }

  void _handlePayload(String payload) {
    try {
      final map = jsonDecode(payload);
      if (map is Map) {
        _handleData(Map<String, dynamic>.from(map));
      }
    } catch (_) {}
  }

  void _recordInbox(String title, String body, Map<String, dynamic> data) {
    NotificationInboxService.instance.addFromPush(
      title: title,
      body: body,
      type: data['type']?.toString() ?? 'GENERIC',
      data: Map<String, dynamic>.from(data),
    );
  }

  void _handleData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final rideId = int.tryParse(data['rideId']?.toString() ?? '');
    final status = data['status']?.toString();

    if (type == 'RIDE_UPDATE' && rideId != null && status != null) {
      onRideUpdate?.call(status, rideId);
      return;
    }

    if (type == 'CHAT_MESSAGE' && rideId != null) {
      return;
    }

    if (type == 'FAMILY_INVITE' || type == 'FAMILY_ACCEPT') {
      _openFamilyProfile();
      return;
    }

    if (type == 'SPLIT_FARE_INVITE'
        || type == 'SPLIT_FARE_PAY'
        || type == 'SPLIT_FARE_ACCEPTED'
        || type == 'SPLIT_FARE_DECLINED'
        || type == 'SPLIT_FARE_PAID') {
      _openSplitFareInvites();
      if (rideId != null) onRideUpdate?.call('refresh', rideId);
    }
  }

  void _openSplitFareInvites() {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const SplitFareInvitesScreen()),
    );
  }

  void _openFamilyProfile() {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(builder: (_) => const FamilyProfileScreen()),
    );
  }

  Future<void> uploadTokenIfLoggedIn() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _upload(token);
  }

  Future<void> _upload(String token) async {
    final passTok = await _storage.read(key: 'passenger_token');
    if (passTok == null) return;

    try {
      await http.patch(
        Uri.parse('${Api.base}/passengers/me/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $passTok',
        },
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (e) {
      debugPrint('FCM token upload failed: $e');
    }
  }

  Future<void> _showLocalNotif(
    String title,
    String body, {
    String? payload,
  }) async {
    await _localNotif.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'novaride_rider',
          'NovaRide Updates',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}
