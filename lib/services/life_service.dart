import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class LivesState {
  const LivesState({required this.lives, required this.nextLifeRemaining});

  final int lives;
  final Duration nextLifeRemaining;
}

class LifeService {
  static const int maxLives = 5;
  static const Duration refillDuration = Duration(minutes: 5);

  static const String _livesKey = 'current_lives';
  static const String _maxLivesMigrationKey = 'max_lives_migration_value';
  static const String _lastLifeUpdateKey = 'last_life_update_millis';

  Future<LivesState> loadState() async {
    final prefs = await SharedPreferences.getInstance();

    final storedMaxLives = prefs.getInt(_maxLivesMigrationKey);
    if (storedMaxLives != maxLives) {
      await prefs.setInt(_livesKey, maxLives);
      await prefs.setInt(_maxLivesMigrationKey, maxLives);
      await prefs.setInt(
        _lastLifeUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    if (!prefs.containsKey(_livesKey)) {
      await prefs.setInt(_livesKey, maxLives);
      await prefs.setInt(_lastLifeUpdateKey, now);
      return const LivesState(
        lives: maxLives,
        nextLifeRemaining: Duration.zero,
      );
    }

    return _refreshState(prefs, now);
  }

  Future<LivesState> consumeLife() async {
    final prefs = await SharedPreferences.getInstance();

    final refreshed = await loadState();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (refreshed.lives <= 0) {
      return refreshed;
    }

    final nextLives = max(0, refreshed.lives - 1);

    await prefs.setInt(_livesKey, nextLives);

    if (refreshed.lives == maxLives) {
      await prefs.setInt(_lastLifeUpdateKey, now);
    }

    return loadState();
  }

  Future<LivesState> addLifeFromReward() async {
    final prefs = await SharedPreferences.getInstance();

    final refreshed = await loadState();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (refreshed.lives >= maxLives) {
      return refreshed;
    }

    final nextLives = min(maxLives, refreshed.lives + 1);

    await prefs.setInt(_livesKey, nextLives);

    if (nextLives >= maxLives) {
      await prefs.setInt(_lastLifeUpdateKey, now);
    }

    return loadState();
  }

  Future<LivesState> _refreshState(
    SharedPreferences prefs,
    int nowMillis,
  ) async {
    var lives = prefs.getInt(_livesKey) ?? maxLives;
    var lastUpdateMillis = prefs.getInt(_lastLifeUpdateKey) ?? nowMillis;

    if (lives >= maxLives) {
      await prefs.setInt(_livesKey, maxLives);
      await prefs.setInt(_lastLifeUpdateKey, nowMillis);

      return const LivesState(
        lives: maxLives,
        nextLifeRemaining: Duration.zero,
      );
    }

    final elapsedMillis = nowMillis - lastUpdateMillis;
    final refillMillis = refillDuration.inMilliseconds;

    if (elapsedMillis >= refillMillis) {
      final gainedLives = elapsedMillis ~/ refillMillis;
      lives = min(maxLives, lives + gainedLives);
      lastUpdateMillis += gainedLives * refillMillis;

      if (lives >= maxLives) {
        lives = maxLives;
        lastUpdateMillis = nowMillis;
      }

      await prefs.setInt(_livesKey, lives);
      await prefs.setInt(_lastLifeUpdateKey, lastUpdateMillis);
    }

    if (lives >= maxLives) {
      return const LivesState(
        lives: maxLives,
        nextLifeRemaining: Duration.zero,
      );
    }

    final nextLifeMillis = refillMillis - (nowMillis - lastUpdateMillis);

    return LivesState(
      lives: lives,
      nextLifeRemaining: Duration(milliseconds: max(0, nextLifeMillis)),
    );
  }
}
