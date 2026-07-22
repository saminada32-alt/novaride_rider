import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'core/services/app_controller.dart';
import 'core/services/crash_reporting.dart';
import 'core/services/network_connectivity_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/rider/account/my_account_all/provider/account_provider.dart';
import 'features/rider/promotions/promo_provider.dart';
import 'app.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackground(RemoteMessage msg) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FirebaseMessaging.onBackgroundMessage(_fcmBackground);
  } catch (e, st) {
    debugPrint('FCM background handler setup failed: $e');
  }

  final appController = AppController();

  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase init failed: $e');
  }

  await CrashReporting.init();
  await appController.loadLocale();

  final promoProvider = PromoProvider();
  final networkService = NetworkConnectivityService();
  unawaited(promoProvider.load());
  unawaited(networkService.start());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appController),
        ChangeNotifierProvider.value(value: networkService),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider.value(value: promoProvider),
      ],
      child: const MyApp(),
    ),
  );
}
