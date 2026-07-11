import 'dart:math';
import 'dart:ui';

import '../models/drop_color_type.dart';
import '../models/falling_item.dart';

class ColorMatchSpinRushController {
  static const List<DropColorType> playableColors = [
    DropColorType.red,
    DropColorType.blue,
    DropColorType.green,
    DropColorType.yellow,
  ];

  final Random _random = Random();

  static const int pointsPerLevel = 12;
  static const double noSpeedUpSeconds = 30;
  static const double reverseBallStartSeconds = 60;
  static const double reverseBallBaseCooldownSeconds = 12;
  static const double reverseSwipeBaseDurationSeconds = 10;

  static const double wheelCenterBottomOffset = 135;
  static const double wheelRadius = 76;

  static const List<DropColorType> _tutorialSequence = [
    DropColorType.red,
    DropColorType.red,
    DropColorType.red,
    DropColorType.blue,
    DropColorType.red,
    DropColorType.red,
    DropColorType.blue,
    DropColorType.green,
    DropColorType.yellow,
    DropColorType.red,
    DropColorType.blue,
    DropColorType.green,
  ];

  final List<FallingItem> _items = [];

  final List<DropColorType> wheelColors = const [
    DropColorType.red,
    DropColorType.blue,
    DropColorType.green,
    DropColorType.yellow,
  ];

  late final Map<DropColorType, int> _bins = {
    for (final color in wheelColors) color: 0,
  };

  int _rotationSteps = 0;
  int _score = 0;
  int _bestScore = 0;
  int _spawnedItemCount = 0;
  double _reverseSwipeRemainingSeconds = 0;
  double _reverseBallCooldownSeconds = 0;
  double _catchPointEffectSeconds = 0;
  DropColorType? _catchPointEffectColor;
  bool _catchPointEffectSuccess = true;
  DropColorType? _lastSpawnedColor;
  int _sameColorStreak = 0;
  bool _useTutorialSequence = false;
  int _catchEventCount = 0;
  int _purpleSpawnEventCount = 0;
  int _lives = 3;

  double _visualRotation = 0;
  double _targetRotation = 0;

  double _spawnTimer = 0;
  double _elapsedGameSeconds = 0;
  double _conveyorOffset = 0;

  bool _isStarted = false;
  bool _isGameOver = false;
  bool _isPaused = false;

  List<FallingItem> get items => List.unmodifiable(_items);
  Map<DropColorType, int> get bins => Map.unmodifiable(_bins);

  int get rotationSteps => _rotationSteps;
  double get conveyorOffset => _conveyorOffset;
  double get visualRotation => _visualRotation;

  int get score => _score;
  int get bestScore => _bestScore;
  bool get isReverseSwipeActive => _reverseSwipeRemainingSeconds > 0;
  double get reverseSwipeRemainingSeconds =>
      max(0.0, _reverseSwipeRemainingSeconds);

  bool get catchPointEffectActive => _catchPointEffectSeconds > 0;
  double get catchPointEffectProgress =>
      _catchPointEffectSeconds <= 0 ? 0 : _catchPointEffectSeconds / 0.34;
  DropColorType? get catchPointEffectColor => _catchPointEffectColor;
  bool get catchPointEffectSuccess => _catchPointEffectSuccess;

  int get catchEventCount => _catchEventCount;
  int get purpleSpawnEventCount => _purpleSpawnEventCount;
  int get lives => _lives;
  int get level => (_score ~/ pointsPerLevel) + 1;

  void setTutorialEnabled(bool enabled) {
    _useTutorialSequence = enabled;
  }

  bool get isStarted => _isStarted;
  bool get isGameOver => _isGameOver;
  bool get isPaused => _isPaused;

  DropColorType get topWheelColor {
    final index = ((-_rotationSteps) % 4 + 4) % 4;
    return wheelColors[index];
  }

  void setLives(int lives) {
    _lives = lives.clamp(0, 3);
  }

  void start() {
    _reset(started: true);
  }

  void restart() {
    _reset(started: true);
  }

  void pause() {
    if (!_isStarted || _isGameOver) return;
    _isPaused = true;
  }

  void resume() {
    if (_isGameOver) return;
    _isPaused = false;
    _isStarted = true;
  }

  void togglePause() {
    if (!_isStarted || _isGameOver) return;
    _isPaused ? resume() : pause();
  }

  void rotateLeft() {
    if (!_isStarted || _isGameOver || _isPaused) return;
    _rotateBySteps(-1);
  }

  void rotateRight() {
    if (!_isStarted || _isGameOver || _isPaused) return;
    _rotateBySteps(1);
  }

  void rotateWithVelocity(double velocity) {
    if (!_isStarted || _isGameOver || _isPaused) return;
    if (velocity == 0) return;

    final direction = velocity < 0 ? -1 : 1;
    final force = velocity.abs();

    final steps = force >= 2600
        ? 3
        : force >= 1350
        ? 2
        : 1;

    _rotateBySteps(direction * steps);
  }

  void update(double dt, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final safeDt = min(dt, 0.033);

    final conveyorSpeed = _isStarted && !_isPaused && !_isGameOver
        ? 58.0
        : 18.0;
    _conveyorOffset += conveyorSpeed * safeDt;

    _updateWheelAnimation(safeDt);

    if (!_isStarted || _isGameOver || _isPaused) return;

    _elapsedGameSeconds += safeDt;

    if (_reverseSwipeRemainingSeconds > 0) {
      _reverseSwipeRemainingSeconds = max(
        0.0,
        _reverseSwipeRemainingSeconds - safeDt,
      );
    }

    if (_reverseBallCooldownSeconds > 0) {
      _reverseBallCooldownSeconds = max(
        0.0,
        _reverseBallCooldownSeconds - safeDt,
      );
    }

    if (_catchPointEffectSeconds > 0) {
      _catchPointEffectSeconds = max(0.0, _catchPointEffectSeconds - safeDt);
    }

    final tutorialActive = _spawnedItemCount < _tutorialSequence.length;
    final secondsAfterGrace = max(0.0, _elapsedGameSeconds - noSpeedUpSeconds);

    final spawnInterval = tutorialActive
        ? 1.85
        : max(0.62, 1.42 - (secondsAfterGrace * 0.006));

    _spawnTimer += safeDt;

    if (_spawnTimer >= spawnInterval) {
      _spawnTimer = 0;
      _catchPointEffectSeconds = 0;
      _catchPointEffectColor = null;
      _catchPointEffectSuccess = true;
      _spawnItem(size);
    }

    final fallSpeed = tutorialActive
        ? 78.0
        : min(390.0, 98.0 + (secondsAfterGrace * 1.15));

    for (final item in _items) {
      item.y += fallSpeed * safeDt;
    }

    _checkCatchPoint(size);
    _items.removeWhere((item) => item.y > size.height + 80);
  }

  void _rotateBySteps(int steps) {
    final reverseAdjustedSteps = isReverseSwipeActive ? -steps : steps;

    _rotationSteps += reverseAdjustedSteps;
    _targetRotation = _rotationSteps * pi / 2;
  }

  void _updateWheelAnimation(double dt) {
    final diff = _targetRotation - _visualRotation;

    if (diff.abs() < 0.001) {
      _visualRotation = _targetRotation;
      return;
    }

    final smoothing = min(1.0, dt * 14);
    _visualRotation += diff * smoothing;
  }

  void _reset({required bool started}) {
    _items.clear();

    for (final color in wheelColors) {
      _bins[color] = 0;
    }

    _rotationSteps = 0;
    _catchEventCount = 0;
    _visualRotation = 0;
    _targetRotation = 0;

    _score = 0;
    _spawnedItemCount = 0;
    _reverseSwipeRemainingSeconds = 0;
    _reverseBallCooldownSeconds = 0;
    _lastSpawnedColor = null;
    _sameColorStreak = 0;
    _spawnTimer = 0;
    _elapsedGameSeconds = 0;
    _isStarted = started;
    _isGameOver = false;
    _isPaused = false;
  }

  bool _shouldSpawnReverseBall() {
    final tutorialStillActive =
        _useTutorialSequence && _spawnedItemCount < _tutorialSequence.length;

    if (tutorialStillActive) return false;
    if (_elapsedGameSeconds < reverseBallStartSeconds) return false;
    if (level < 3) return false;
    if (_reverseBallCooldownSeconds > 0) return false;
    if (isReverseSwipeActive) return false;

    return _random.nextDouble() < _reverseBallChance;
  }

  double get _reverseBallChance {
    if (_elapsedGameSeconds < reverseBallStartSeconds) {
      return 0.0;
    }

    final levelBonus = max(0, level - 3) * 0.012;
    final timeBonus = min(
      0.035,
      max(0.0, _elapsedGameSeconds - reverseBallStartSeconds) / 240 * 0.035,
    );

    return min(0.12, 0.04 + levelBonus + timeBonus);
  }

  double get _reverseBallCooldownDuration {
    final levelReduction = max(0, level - 3) * 0.35;
    return max(8.0, reverseBallBaseCooldownSeconds - levelReduction);
  }

  double get _reverseSwipeDuration => reverseSwipeBaseDurationSeconds;

  void _activateReverseSwipe() {
    _reverseSwipeRemainingSeconds = _reverseSwipeDuration;
  }

  DropColorType _resolveNextColor() {
    if (_useTutorialSequence && _spawnedItemCount < _tutorialSequence.length) {
      return _tutorialSequence[_spawnedItemCount];
    }

    if (_shouldSpawnReverseBall()) {
      _reverseBallCooldownSeconds = _reverseBallCooldownDuration;
      return DropColorType.purple;
    }

    final lastColor = _lastSpawnedColor;

    if (_elapsedGameSeconds >= 10 &&
        lastColor != null &&
        _sameColorStreak >= 2) {
      return _randomDifferentColor(lastColor);
    }

    if (lastColor != null && _random.nextDouble() < _sameColorChance) {
      return lastColor;
    }

    if (lastColor == null) {
      return playableColors[_random.nextInt(playableColors.length)];
    }

    return _randomDifferentColor(lastColor);
  }

  double get _sameColorChance {
    if (_elapsedGameSeconds <= 45) {
      return 0.70;
    }

    if (_elapsedGameSeconds < 60) {
      final transition = (_elapsedGameSeconds - 45) / 15;
      return 0.70 + ((0.40 - 0.70) * transition);
    }

    final levelPenalty = max(0, level - 1) * 0.035;
    final timePenalty = min(
      0.18,
      max(0.0, _elapsedGameSeconds - 60) / 300 * 0.18,
    );

    return max(0.15, 0.40 - levelPenalty - timePenalty);
  }

  DropColorType _randomDifferentColor(DropColorType currentColor) {
    final availableColors = playableColors
        .where((color) => color != currentColor)
        .toList();

    return availableColors[_random.nextInt(availableColors.length)];
  }

  void _spawnItem(Size size) {
    final colorType = _resolveNextColor();

    if (colorType == DropColorType.purple) {
      _purpleSpawnEventCount++;
    }

    if (colorType != DropColorType.purple) {
      if (_lastSpawnedColor == colorType) {
        _sameColorStreak++;
      } else {
        _sameColorStreak = 1;
      }

      _lastSpawnedColor = colorType;
    }

    _spawnedItemCount++;

    _items.add(
      FallingItem(x: size.width / 2, y: 224, colorType: colorType, radius: 18),
    );
  }

  void _checkCatchPoint(Size size) {
    final wheelCenterY = size.height - wheelCenterBottomOffset;
    final catchY = wheelCenterY - wheelRadius;

    for (final item in List<FallingItem>.from(_items)) {
      if (item.y >= catchY) {
        if (item.colorType == topWheelColor) {
          _catchItem(item);
        } else {
          _finishGame();
        }
      }
    }
  }

  void _triggerCatchPointEffect(
    DropColorType colorType, {
    required bool success,
  }) {
    _catchPointEffectColor = colorType;
    _catchPointEffectSuccess = success;
    _catchPointEffectSeconds = 0.34;
  }

  void _catchItem(FallingItem item) {
    _triggerCatchPointEffect(item.colorType, success: true);

    if (item.colorType == DropColorType.purple) {
      _items.remove(item);
      _activateReverseSwipe();
      return;
    }

    _catchEventCount++;
    _items.remove(item);

    final currentCount = _bins[item.colorType] ?? 0;
    final nextCount = currentCount + 1;

    if (nextCount >= 3) {
      _bins[item.colorType] = 0;
      _score += 6;
    } else {
      _bins[item.colorType] = nextCount;
      _score += 1;
    }
  }

  void _finishGame() {
    _isGameOver = true;
    _isStarted = false;
    _isPaused = false;

    if (_score > _bestScore) {
      _bestScore = _score;
    }
  }
}
