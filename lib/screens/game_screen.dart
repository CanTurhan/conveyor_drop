import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/conveyor_drop_controller.dart';
import '../painters/game_painter.dart';
import '../services/life_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const Color darkBrown = Color(0xFF3A2A1C);
  static const Color darkestBrown = Color(0xFF21160E);
  static const Color cream = Color(0xFFFFF6E8);
  static const Color warmCream = Color(0xFFFFE3B8);
  static const Color accent = Color(0xFFFFC63D);

  final ConveyorDropController _controller = ConveyorDropController();
  final LifeService _lifeService = LifeService();

  late final Ticker _ticker;
  Timer? _lifeTimer;

  Duration _lastElapsed = Duration.zero;
  Size _lastSize = Size.zero;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  int _lives = LifeService.maxLives;
  Duration _nextLifeRemaining = Duration.zero;
  bool _gameOverLifeHandled = false;

  double _hintVisibleSeconds = 0;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
    _ticker.start();

    _loadLives();

    _lifeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshLives(),
    );
  }

  @override
  void dispose() {
    _lifeTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds /
              Duration.microsecondsPerSecond;

    _lastElapsed = elapsed;

    if (_lastSize != Size.zero) {
      _controller.update(dt, _lastSize);
    }

    if (_controller.isGameOver && !_gameOverLifeHandled) {
      _gameOverLifeHandled = true;
      _consumeLifeAfterGameOver();
    }

    if (_controller.isStarted &&
        !_controller.isPaused &&
        !_controller.isGameOver &&
        _hintVisibleSeconds < 15) {
      _hintVisibleSeconds += dt;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLives() async {
    final state = await _lifeService.loadState();

    if (!mounted) return;

    setState(() {
      _lives = state.lives;
      _nextLifeRemaining = state.nextLifeRemaining;
      _controller.setLives(_lives);
    });
  }

  Future<void> _refreshLives() async {
    final state = await _lifeService.loadState();

    if (!mounted) return;

    setState(() {
      _lives = state.lives;
      _nextLifeRemaining = state.nextLifeRemaining;
      _controller.setLives(_lives);
    });
  }

  Future<void> _consumeLifeAfterGameOver() async {
    final state = await _lifeService.consumeLife();

    if (!mounted) return;

    setState(() {
      _lives = state.lives;
      _nextLifeRemaining = state.nextLifeRemaining;
      _controller.setLives(_lives);
    });
  }

  Future<void> _addLifeFromRewardPlaceholder() async {
    final state = await _lifeService.addLifeFromReward();

    if (!mounted) return;

    setState(() {
      _lives = state.lives;
      _nextLifeRemaining = state.nextLifeRemaining;
      _controller.setLives(_lives);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rewarded Ad placeholder: +1 life added.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity == 0) return;

    _controller.rotateWithVelocity(velocity);
    _vibrate();
  }

  void _vibrate() {
    if (!_vibrationEnabled) return;
    HapticFeedback.selectionClick();
  }

  Future<void> _startGame() async {
    await _refreshLives();

    if (_lives <= 0) return;

    setState(() {
      _hintVisibleSeconds = 0;
      _gameOverLifeHandled = false;
      _controller.start();
    });
  }

  Future<void> _restartGame() async {
    await _refreshLives();

    if (_lives <= 0) return;

    setState(() {
      _hintVisibleSeconds = 0;
      _gameOverLifeHandled = false;
      _controller.restart();
    });
  }

  void _togglePause() {
    setState(() {
      _controller.togglePause();
    });
  }

  Future<void> _openSettings() async {
    final shouldResumeAfterSettings =
        _controller.isStarted &&
        !_controller.isPaused &&
        !_controller.isGameOver;

    if (shouldResumeAfterSettings) {
      setState(() {
        _controller.pause();
      });
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(colors: [cream, warmCream]),
                    border: Border.all(color: darkBrown, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 24,
                        offset: Offset(0, 12),
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: darkBrown,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SettingsToggle(
                        icon: Icons.volume_up_rounded,
                        label: 'Sound',
                        value: _soundEnabled,
                        onChanged: (value) {
                          setDialogState(() => _soundEnabled = value);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      _SettingsToggle(
                        icon: Icons.vibration_rounded,
                        label: 'Vibration',
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setDialogState(() => _vibrationEnabled = value);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBrown,
                            foregroundColor: cream,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (shouldResumeAfterSettings && !_controller.isGameOver) {
      setState(() {
        _controller.resume();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    _lastSize = screenSize;

    return Scaffold(
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _handleSwipe,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: GamePainter(_controller),
                  child: const SizedBox.expand(),
                ),
              ),
              _buildTopHud(),
              if (!_controller.isStarted &&
                  !_controller.isGameOver &&
                  _lives <= 0)
                _buildNoLivesPanel(),
              if (!_controller.isStarted &&
                  !_controller.isGameOver &&
                  _lives > 0)
                _buildStartPanel(),
              if (_controller.isPaused) _buildPausePanel(),
              if (_controller.isGameOver) _buildGameOverPanel(),
              if (_controller.isStarted &&
                  !_controller.isPaused &&
                  !_controller.isGameOver &&
                  _hintVisibleSeconds < 15)
                _buildGameHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      height: 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: darkBrown,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: darkestBrown, width: 3),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color.fromRGBO(0, 0, 0, 0.24),
            ),
          ],
        ),
        child: Row(
          children: [
            _FrameButton(
              icon: _controller.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              enabled: _controller.isStarted && !_controller.isGameOver,
              onTap: _togglePause,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HudChip(label: 'SCORE', value: '${_controller.score}'),
                  const SizedBox(width: 6),
                  _HudChip(
                    label: 'LEVEL',
                    value: '${_controller.level}',
                    accent: true,
                  ),
                  const SizedBox(width: 6),
                  _HudChip(label: 'BEST', value: '${_controller.bestScore}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _FrameButton(
              icon: Icons.settings_rounded,
              enabled: true,
              onTap: _openSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartPanel() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 110, 26, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(colors: [cream, warmCream]),
                border: Border.all(color: darkBrown, width: 3),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    color: Color.fromRGBO(0, 0, 0, 0.24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: darkBrown,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.sync_rounded,
                      color: accent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Conveyor Drop',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Catch the right color before it hits the wheel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(58, 42, 28, 0.68),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _HowToPlayRow(
                    number: '1',
                    text: 'Match the same colored balls and holes!',
                  ),
                  const SizedBox(height: 8),
                  const _HowToPlayRow(
                    number: '2',
                    text: 'Swipe left or right to rotate',
                  ),
                  const SizedBox(height: 8),
                  const _HowToPlayRow(
                    number: '3',
                    text: 'Collect 3 same colors for bonus!',
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBrown,
                        foregroundColor: cream,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'PLAY',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPausePanel() {
    return _CenterPanel(
      title: 'Paused',
      buttonText: 'RESUME',
      onPressed: _togglePause,
    );
  }

  Widget _buildGameOverPanel() {
    final hasLives = _lives > 0;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: darkBrown, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasLives ? 'Game Over' : 'No Lives',
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultBox(
                          label: 'Score',
                          value: '${_controller.score}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResultBox(label: 'Lives', value: '$_lives'),
                      ),
                    ],
                  ),
                  if (!hasLives) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Next life in ${_formatRemaining(_nextLifeRemaining)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _addLifeFromRewardPlaceholder,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkBrown,
                          side: const BorderSide(color: darkBrown, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'WATCH AD +1 LIFE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: hasLives ? _restartGame : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBrown,
                        disabledBackgroundColor: const Color.fromRGBO(
                          58,
                          42,
                          28,
                          0.28,
                        ),
                        foregroundColor: cream,
                        disabledForegroundColor: const Color.fromRGBO(
                          255,
                          246,
                          232,
                          0.70,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        hasLives ? 'RETRY' : 'WAIT',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoLivesPanel() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 110, 26, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: darkBrown, width: 3),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    color: Color.fromRGBO(0, 0, 0, 0.24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF4E55),
                    size: 54,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No Lives',
                    style: TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Next life in ${_formatRemaining(_nextLifeRemaining)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can hold up to 3 lives.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color.fromRGBO(58, 42, 28, 0.65),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _addLifeFromRewardPlaceholder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkBrown,
                        side: const BorderSide(color: darkBrown, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'WATCH AD +1 LIFE',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameHint() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 310,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 246, 232, 0.82),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color.fromRGBO(58, 42, 28, 0.15)),
          ),
          child: const Text(
            'Swipe to rotate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color.fromRGBO(58, 42, 28, 0.70),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameButton extends StatelessWidget {
  const _FrameButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _GameScreenState.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _GameScreenState.darkestBrown, width: 2),
          ),
          child: Icon(icon, color: _GameScreenState.darkBrown, size: 25),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 44,
      decoration: BoxDecoration(
        color: accent ? _GameScreenState.accent : _GameScreenState.cream,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _GameScreenState.darkestBrown, width: 2),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Color.fromRGBO(58, 42, 28, 0.60),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: _GameScreenState.darkBrown,
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

class _HowToPlayRow extends StatelessWidget {
  const _HowToPlayRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 246, 232, 0.72),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color.fromRGBO(58, 42, 28, 0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _GameScreenState.darkBrown,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: _GameScreenState.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: _GameScreenState.darkBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 246, 232, 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(58, 42, 28, 0.13)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _GameScreenState.darkBrown, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label ${value ? "On" : "Off"}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _GameScreenState.darkBrown,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _GameScreenState.darkBrown,
            activeTrackColor: _GameScreenState.accent,
            inactiveThumbColor: const Color(0xFFB9A58D),
            inactiveTrackColor: _GameScreenState.warmCream,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _GameScreenState.warmCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _GameScreenState.darkBrown, width: 2),
      ),
      child: Center(
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color.fromRGBO(58, 42, 28, 0.58),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _GameScreenState.darkBrown,
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

class _CenterPanel extends StatelessWidget {
  const _CenterPanel({
    required this.title,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _GameScreenState.cream,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _GameScreenState.darkBrown, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: _GameScreenState.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _GameScreenState.darkBrown,
                        foregroundColor: _GameScreenState.cream,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
