import 'package:flutter/material.dart';
import '../../core/utils/session_cache.dart';
import '../auth/profile_setup/profile_setup_screen.dart';
import '../auth/intro/intro_screen.dart';
import '../rider/home/rider_home_screen.dart';

enum RiderOnboardingStep {
  profileSetup,
  intro,
}

class RiderOnboardingRouter {
  RiderOnboardingRouter._();

  static Future<void> saveStep(RiderOnboardingStep step) =>
      SessionCache.saveRiderOnboardingStep(step.name);

  static Future<RiderOnboardingStep?> _loadStep() async {
    final raw = await SessionCache.loadRiderOnboardingStep();
    if (raw == null) return null;
    for (final step in RiderOnboardingStep.values) {
      if (step.name == raw) return step;
    }
    return null;
  }

  /// Resume rider onboarding — profile info entry or intro after profile done.
  static Future<void> resumeIncomplete(
    BuildContext context, {
    required bool profileCompleted,
  }) async {
    if (!profileCompleted) {
      await saveStep(RiderOnboardingStep.profileSetup);
      _replace(context, const ProfileSetupScreen());
      return;
    }

    final cached = await _loadStep();
    if (cached == RiderOnboardingStep.intro) {
      _replace(context, const IntroScreen());
      return;
    }

    _replace(context, const RiderHomeScreen());
  }

  static void _replace(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
  }
}
