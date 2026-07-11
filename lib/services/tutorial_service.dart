import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';

  Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  Future<void> setTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  Future<void> resetTutorialForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
  }

  static const String _purpleTutorialSeenKey = 'purple_tutorial_seen';

  Future<bool> isPurpleTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_purpleTutorialSeenKey) ?? false;
  }

  Future<void> setPurpleTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_purpleTutorialSeenKey, true);
  }

  Future<void> resetPurpleTutorialForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_purpleTutorialSeenKey);
  }
}
