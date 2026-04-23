import 'dart:async';
import '../models/game_config.dart';

/// Blitz timer event emitted via stream.
class TimerEvent {
  final int whiteRemainingMs;
  final int blackRemainingMs;
  final bool isWhiteTurn;
  final bool whiteExpired;
  final bool blackExpired;

  const TimerEvent({
    required this.whiteRemainingMs,
    required this.blackRemainingMs,
    required this.isWhiteTurn,
    this.whiteExpired = false,
    this.blackExpired = false,
  });

  bool get anyExpired => whiteExpired || blackExpired;
  String get whiteFormatted => _format(whiteRemainingMs);
  String get blackFormatted => _format(blackRemainingMs);

  static String _format(int ms) {
    final totalSec = (ms / 1000).ceil();
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double whiteProgress(int totalMs) => (whiteRemainingMs / totalMs).clamp(0.0, 1.0);
  double blackProgress(int totalMs) => (blackRemainingMs / totalMs).clamp(0.0, 1.0);

  bool get whiteWarning => whiteRemainingMs <= 10000 && !whiteExpired;
  bool get blackWarning => blackRemainingMs <= 10000 && !blackExpired;
  bool get whiteCritical => whiteRemainingMs <= 5000 && !whiteExpired;
  bool get blackCritical => blackRemainingMs <= 5000 && !blackExpired;
}

/// Millisecond-accurate chess blitz timer using Dart Stream.
///
/// Rules (per blitz_mode.md):
/// - Sudden Death: player loses when clock hits 0
/// - Increment (Fischer): add [incrementMs] to current player after each move
///
/// Usage:
///   final service = BlitzTimerService(config: config);
///   service.events.listen((e) { ... });
///   service.start(isWhiteTurn: true);
///   // on each move:
///   service.onMoveMade(nextIsWhiteTurn: false);
///   service.dispose();
class BlitzTimerService {
  final TimeControl timeControl;

  late int _whiteMs;
  late int _blackMs;
  bool _isWhiteTurn = true;
  bool _running = false;
  bool _disposed = false;

  Timer? _ticker;
  final _controller = StreamController<TimerEvent>.broadcast();
  DateTime? _lastTick;

  static const _tickIntervalMs = 100; // 100ms tick for smooth UI

  BlitzTimerService({required this.timeControl}) {
    _whiteMs = timeControl.minutes * 60 * 1000;
    _blackMs = timeControl.minutes * 60 * 1000;
  }

  Stream<TimerEvent> get events => _controller.stream;
  int get totalMs => timeControl.minutes * 60 * 1000;
  int get incrementMs => timeControl.incrementSec * 1000;

  bool get isRunning => _running;
  bool get whiteExpired => _whiteMs <= 0;
  bool get blackExpired => _blackMs <= 0;

  /// Start/resume the timer for the given player's turn.
  void start({required bool isWhiteTurn}) {
    if (_disposed) return;
    _isWhiteTurn = isWhiteTurn;
    _running = true;
    _lastTick = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      _onTick,
    );
  }

  /// Pause the timer (e.g. game paused or menu opened).
  void pause() {
    _running = false;
    _ticker?.cancel();
    _ticker = null;
  }

  /// Called after each move — switches active player + applies increment (Fischer).
  void onMoveMade({required bool nextIsWhiteTurn}) {
    if (_disposed) return;

    // Apply increment to the player who JUST moved (Fischer clock rule)
    if (_isWhiteTurn) {
      _whiteMs += incrementMs;
    } else {
      _blackMs += incrementMs;
    }

    _isWhiteTurn = nextIsWhiteTurn;
    _lastTick = DateTime.now();
    _emit();
  }

  void _onTick(Timer _) {
    if (!_running || _disposed) return;

    final now = DateTime.now();
    final elapsed = now.difference(_lastTick!).inMilliseconds;
    _lastTick = now;

    if (_isWhiteTurn) {
      _whiteMs = (_whiteMs - elapsed).clamp(0, totalMs);
    } else {
      _blackMs = (_blackMs - elapsed).clamp(0, totalMs);
    }

    _emit();

    // Stop on expiry
    if (_whiteMs <= 0 || _blackMs <= 0) {
      _running = false;
      _ticker?.cancel();
    }
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(TimerEvent(
      whiteRemainingMs: _whiteMs,
      blackRemainingMs: _blackMs,
      isWhiteTurn: _isWhiteTurn,
      whiteExpired: _whiteMs <= 0,
      blackExpired: _blackMs <= 0,
    ));
  }

  /// Reset to full time (new game).
  void reset({bool isWhiteTurn = true}) {
    _whiteMs = timeControl.minutes * 60 * 1000;
    _blackMs = timeControl.minutes * 60 * 1000;
    _isWhiteTurn = isWhiteTurn;
    _running = false;
    _ticker?.cancel();
    _emit();
  }

  void dispose() {
    _disposed = true;
    _running = false;
    _ticker?.cancel();
    _controller.close();
  }
}
