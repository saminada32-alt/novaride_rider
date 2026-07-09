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
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await CrashReporting.init();
  FirebaseMessaging.onBackgroundMessage(_fcmBackground);

  final appController = AppController();
  await appController.loadLocale();

  final promoProvider = PromoProvider();
  await promoProvider.load();

  final networkService = NetworkConnectivityService();
  await networkService.start();

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
