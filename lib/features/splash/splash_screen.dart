import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/a11y.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/welcome/welcome_screen.dart';
import '../auth/navigation/rider_onboarding_router.dart';
import '../rider/home/rider_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _check();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final status = await context.read<AuthProvider>().checkStatus();
      if (!mounted) return;

      switch (status) {
        case RiderStatus.returning:
          _go(const RiderHomeScreen(), fast: true);
          break;
        case RiderStatus.newUser:
          unawaited(
            RiderOnboardingRouter.resumeIncomplete(
              context,
              profileCompleted: false,
            ),
          );
          break;
        case RiderStatus.notLoggedIn:
          _go(const WelcomeScreen());
          break;
      }
    } catch (e, st) {
      debugPrint('Splash check failed: $e\n$st');
      if (!mounted) return;
      final tok = context.read<AuthProvider>().token;
      if (tok != null) {
        unawaited(
          RiderOnboardingRouter.resumeIncomplete(
            context,
            profileCompleted:
                context.read<AuthProvider>().passenger?.profileCompleted ??
                false,
          ),
        );
      } else {
        _go(const WelcomeScreen());
      }
    }
  }

  void _go(Widget w, {bool fast = false}) => Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      transitionDuration: Duration(milliseconds: fast ? 150 : 200),
      pageBuilder: (_, _, _) => w,
      transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return A11yScreen(
      label: local.splashTitle,
      child: Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                local.splashTitle,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                local.splashSubtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.green,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
