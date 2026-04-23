import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/providers/user_provider.dart';
import '../../../domain/models/skin_registry.dart';

/// Animated particle background widget to give dynamic look on main screen
class ParticleBackground extends ConsumerStatefulWidget {
  final Widget child;
  const ParticleBackground({super.key, required this.child});

  @override
  ConsumerState<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends ConsumerState<ParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(_random));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final activeTheme = SkinRegistry.getTheme(settings.themeIndex);

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        ),
        // Particles
        ...(_particles.map((p) {
          final t = (_controller.value + p.offset) % 1.0;
          final color = [activeTheme.primary, activeTheme.secondary, AppTheme.gold][p.colorIndex];
          return Positioned(
            left: p.x * MediaQuery.of(context).size.width,
            top: (1 - t) * MediaQuery.of(context).size.height,
            child: Opacity(
              opacity: (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) * p.opacity,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.8), blurRadius: p.size * 2),
                  ],
                ),
              ),
            ),
          );
        })),
        // Grid overlay
        CustomPaint(
          painter: _GridPainter(activeTheme),
          child: widget.child,
        ),
      ],
    );
  }
}

class _Particle {
  final double x;
  final double offset;
  final double size;
  final double opacity;
  final int colorIndex;

  _Particle(Random random)
      : x = random.nextDouble(),
        offset = random.nextDouble(),
        size = random.nextDouble() * 3 + 1,
        opacity = random.nextDouble() * 0.6 + 0.1,
        colorIndex = random.nextInt(3);
}

class _GridPainter extends CustomPainter {
  final ThemeColors theme;
  _GridPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.primary.withOpacity(0.04)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
