import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/app_controller.dart';
import 'core/widgets/connectivity_overlay.dart';
import 'core/services/notification_inbox_service.dart';
import 'core/services/rider_fcm_service.dart';
import 'core/services/crash_reporting.dart';
import 'features/splash/splash_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(CrashReporting.init());
      NotificationInboxService.instance.loadCache();
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        RiderFcmService.instance.init();
        NotificationInboxService.instance.loadFromApi();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      locale: ctrl.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: ctrl.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: ConnectivityOverlay(child: child!),
        );
      },
      home: const SplashScreen(),
    );
  }
}
