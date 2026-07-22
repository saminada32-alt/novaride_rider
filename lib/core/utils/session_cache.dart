import 'package:shared_preferences/shared_preferences.dart';

/// Last known session flags — used when `/passengers/me` is slow or unreachable (Syria 2G/3G).
class SessionCache {
  SessionCache._();

  static const _profileCompleted = 'rider_profile_completed';
  static const _riderOnboardingStep = 'rider_onboarding_step';

  static Future<void> saveRiderProfileCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileCompleted, completed);
  }

  static Future<bool?> loadRiderProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileCompleted);
  }

  static Future<void> saveRiderOnboardingStep(String step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_riderOnboardingStep, step);
  }

  static Future<String?> loadRiderOnboardingStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_riderOnboardingStep);
  }

  static Future<void> clearRider() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCompleted);
    await prefs.remove(_riderOnboardingStep);
  }
}
