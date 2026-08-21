import 'package:shared_preferences/shared_preferences.dart';

const String onboardingCompletedKey = 'onboardingCompleted';

class OnboardingService {
  OnboardingService._();

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedKey, true);
  }
}
