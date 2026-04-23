import 'package:flutter/material.dart';

/// Countdown timer widget for blitz chess.
class GameTimerWidget extends StatefulWidget {
  final int totalSeconds;
  final bool isActive;
  final Color color;
  final VoidCallback? onExpired;

  const GameTimerWidget({
    super.key,
    required this.totalSeconds,
    required this.isActive,
    required this.color,
    this.onExpired,
  });

  @override
  State<GameTimerWidget> createState() => GameTimerWidgetState();
}

class GameTimerWidgetState extends State<GameTimerWidget>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late AnimationController _tickController;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isActive) _startTick();
  }

  @override
  void didUpdateWidget(GameTimerWidget old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _startTick();
    } else if (!widget.isActive && old.isActive) {
      _tickController.stop();
    }
  }

  void _startTick() {
    _tickController.repeat();
    _tickController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.isActive && !_expired) {
        if (_remaining > 0) {
          setState(() => _remaining--);
          _tickController.forward(from: 0);
        } else {
          _expired = true;
          widget.onExpired?.call();
        }
      }
    });
  }

  /// Reset timer (called when new game starts)
  void reset() {
    setState(() {
      _remaining = widget.totalSeconds;
      _expired = false;
    });
    if (widget.isActive) {
      _tickController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  String get _formatted {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => _remaining / widget.totalSeconds;

  bool get _isWarning => _remaining <= 10 && _remaining > 0;
  bool get _isCritical => _remaining <= 5 && _remaining > 0;

  @override
  Widget build(BuildContext context) {
    final displayColor = _expired
        ? Colors.red
        : _isCritical
            ? Colors.red
            : _isWarning
                ? Colors.orange
                : widget.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isActive
            ? displayColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActive
              ? displayColor.withValues(alpha: 0.5)
              : displayColor.withValues(alpha: 0.2),
        ),
        boxShadow: widget.isActive && !_expired
            ? [BoxShadow(color: displayColor.withValues(alpha: 0.3), blurRadius: 8)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _progress.clamp(0, 1),
                  strokeWidth: 3,
                  backgroundColor: displayColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                ),
                if (_isCritical)
                  AnimatedBuilder(
                    animation: _tickController,
                    builder: (_, __) => Opacity(
                      opacity: _tickController.value > 0.5 ? 1.0 : 0.3,
                      child: Icon(Icons.timer_rounded, color: displayColor, size: 14),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _expired ? '00:00' : _formatted,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: displayColor,
              letterSpacing: 1,
              shadows: widget.isActive
                  ? [Shadow(color: displayColor.withValues(alpha: 0.5), blurRadius: 6)]
                  : [],
            ),
          ),
        ],
      ),
    );
  }
}
