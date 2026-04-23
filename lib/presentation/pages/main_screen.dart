import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/particle_background.dart';
import '../widgets/common_widgets.dart';
import 'game_mode_selector_screen.dart';
import 'store_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late AnimationController _logoAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _logoScale;
  late Animation<double> _logoPulse;
  late Animation<double> _logoFade;

  // Mock gold value (would be from Riverpod state in full implementation)
  int _gold = 1250;

  @override
  void initState() {
    super.initState();

    _logoAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: Curves.elasticOut),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _logoPulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () => _logoAnim.forward());
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildMenuButtons(),
                        const SizedBox(height: 32),
                        _buildVersion(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Badge
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.neonCyan,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.neonCyanGlow, blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text('MYSTERY WAR', style: AppTheme.labelSmall),
            ],
          ),
          GoldBadge(amount: _gold),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Column(
          children: [
            // Chess Knight Icon with glow
            ScaleTransition(
              scale: _logoPulse,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.neonCyan.withOpacity(0.2),
                      AppTheme.neonPurple.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.neonCyan.withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
                    BoxShadow(color: AppTheme.neonPurple.withOpacity(0.3), blurRadius: 60),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '♞',
                    style: TextStyle(
                      fontSize: 72,
                      color: AppTheme.textPrimary,
                      shadows: [
                        Shadow(color: AppTheme.neonCyan, blurRadius: 20),
                        Shadow(color: AppTheme.neonPurple, blurRadius: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.cyanPurpleGradient.createShader(bounds),
              child: Text(
                'CHESS AI',
                style: AppTheme.displayLarge.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'M Y S T E R Y   W A R',
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.gold,
                fontSize: 13,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            // Decorative divider
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDividerLine(AppTheme.neonCyan),
                const SizedBox(width: 12),
                const Text('✦', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                const SizedBox(width: 12),
                _buildDividerLine(AppTheme.neonPurple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerLine(Color color) {
    return Container(
      width: 60,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, color, Colors.transparent],
        ),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        _MainMenuCard(
          label: 'START GAME',
          description: 'Normal • Mystery • Champion',
          icon: Icons.play_arrow_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF003D40), Color(0xFF001A1C)],
          ),
          borderColor: AppTheme.neonCyan,
          glowColor: AppTheme.neonCyan,
          onTap: () => _navigate(const GameModeSelectorScreen()),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MainMenuCard(
                label: 'STORE',
                description: 'Skins & Gold',
                icon: Icons.storefront_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1F00), Color(0xFF1A1200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppTheme.gold,
                glowColor: AppTheme.gold,
                onTap: () => _navigate(const StoreScreen()),
                compact: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MainMenuCard(
                label: 'CONFIG',
                description: 'Audio • Hints',
                icon: Icons.tune_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E003D), Color(0xFF0D001A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderColor: AppTheme.neonPurple,
                glowColor: AppTheme.neonPurple,
                onTap: () => _navigate(const SettingsScreen()),
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVersion() {
    return Text(
      'v1.0.0 • AI-Powered Chess Engine',
      style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
    );
  }
}

class _MainMenuCard extends StatefulWidget {
  final String label;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color borderColor;
  final Color glowColor;
  final VoidCallback onTap;
  final bool compact;

  const _MainMenuCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.borderColor,
    required this.glowColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_MainMenuCard> createState() => _MainMenuCardState();
}

class _MainMenuCardState extends State<_MainMenuCard> with SingleTickerProviderStateMixin {
  late AnimationController _hover;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _glowAnim = Tween(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _hover, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hover.forward(),
      onTapUp: (_) {
        _hover.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hover.reverse(),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) {
          return Container(
            padding: widget.compact
                ? const EdgeInsets.all(20)
                : const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor.withOpacity(0.7), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.3 * _glowAnim.value),
                  blurRadius: 20 * _glowAnim.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: widget.compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(widget.icon, color: widget.borderColor, size: 26),
                      const SizedBox(height: 10),
                      Text(widget.label, style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(widget.description, style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: widget.borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: widget.borderColor.withOpacity(0.3)),
                        ),
                        child: Icon(widget.icon, color: widget.borderColor, size: 28),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.label, style: AppTheme.titleLarge.copyWith(color: widget.borderColor)),
                          const SizedBox(height: 4),
                          Text(widget.description, style: AppTheme.bodyMedium),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded, color: widget.borderColor.withOpacity(0.5)),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
