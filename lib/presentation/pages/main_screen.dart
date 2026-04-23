import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/providers/user_provider.dart';
import '../widgets/particle_background.dart';
import '../widgets/common_widgets.dart';
import '../../domain/models/skin_registry.dart';
import 'game_mode_selector_screen.dart';
import 'store_screen.dart';
import 'settings_screen.dart';
import 'inventory_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with TickerProviderStateMixin {
  late AnimationController _logoAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _logoScale;
  late Animation<double> _logoPulse;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _logoScale = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _logoAnim, curve: Curves.elasticOut));
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoAnim, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _logoPulse = Tween(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));

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
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final gold = ref.watch(goldProvider);
    final activePieceSkin = ref.watch(activePieceSkinProvider);
    final theme = SkinRegistry.getTheme(ref.watch(activeThemeIndexProvider));

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(gold, theme),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildLogo(theme),
                        const SizedBox(height: 40),
                        _buildMenuButtons(activePieceSkin, theme),
                        const SizedBox(height: 28),
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

  Widget _buildTopBar(int gold, ThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: theme.primary, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.6), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              Text(S.get('app_subtitle'), style: AppTheme.labelSmall),
            ],
          ),
          GoldBadge(amount: gold),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeColors theme) {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Column(
          children: [
            ScaleTransition(
              scale: _logoPulse,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    theme.primary.withValues(alpha: 0.2),
                    theme.secondary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ]),
                  boxShadow: [
                    BoxShadow(color: theme.primary.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5),
                    BoxShadow(color: theme.secondary.withValues(alpha: 0.3), blurRadius: 60),
                  ],
                ),
                child: Center(
                  child: Text('♞', style: TextStyle(
                    fontSize: 72, color: AppTheme.textPrimary,
                    shadows: [
                      Shadow(color: theme.primary, blurRadius: 20),
                      Shadow(color: theme.secondary, blurRadius: 40),
                    ],
                  )),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [theme.primary, theme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text('CHESS AI', style: AppTheme.displayLarge.copyWith(color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text('M Y S T E R Y   W A R',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.gold, fontSize: 13, letterSpacing: 4)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dividerLine(theme.primary),
                const SizedBox(width: 12),
                const Text('✦', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                const SizedBox(width: 12),
                _dividerLine(theme.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dividerLine(Color color) {
    return Container(
      width: 60, height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.transparent, color, Colors.transparent]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
      ),
    );
  }

  Widget _buildMenuButtons(String activePieceSkin, ThemeColors theme) {
    return Column(
      children: [
        // START GAME — full width
        _MainMenuCard(
          label: S.get('start_game'),
          description: S.get('start_desc'),
          icon: Icons.play_arrow_rounded,
          gradient: const LinearGradient(colors: [Color(0xFF003D40), Color(0xFF001A1C)]),
          borderColor: theme.primary,
          glowColor: theme.primary,
          onTap: () => _navigate(const GameModeSelectorScreen()),
        ),
        const SizedBox(height: 14),

        // STORE + CONFIG row
        Row(
          children: [
            Expanded(
              child: _MainMenuCard(
                label: S.get('store'),
                description: S.get('store_desc'),
                icon: Icons.storefront_rounded,
                gradient: const LinearGradient(
                    colors: [Color(0xFF2A1F00), Color(0xFF1A1200)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderColor: AppTheme.gold,
                glowColor: AppTheme.gold,
                onTap: () => _navigate(const StoreScreen()),
                compact: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _MainMenuCard(
                label: 'Settings',
                description: 'Audio • Hints • Theme',
                icon: Icons.tune_rounded,
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E003D), Color(0xFF0D001A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderColor: theme.secondary,
                glowColor: theme.secondary,
                onTap: () => _navigate(const SettingsScreen()),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // MY ITEMS — full width
        _MainMenuCard(
          label: S.get('my_items'),
          description: S.get('my_items_desc'),
          icon: Icons.style_rounded,
          gradient: const LinearGradient(
              colors: [Color(0xFF001A30), Color(0xFF000D18)]),
          borderColor: theme.primary,
          glowColor: theme.primary,
          onTap: () => _navigate(const InventoryScreen()),
          trailing: Text(
            '♘',
            style: TextStyle(
              fontSize: 28,
              shadows: [
                Shadow(color: theme.primary.withValues(alpha: 0.7), blurRadius: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersion() {
    return Text(
      S.get('version'),
      style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
    );
  }
}

// ── Main Menu Card ──────────────────────────────────────────────────────────

class _MainMenuCard extends StatefulWidget {
  final String label;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color borderColor;
  final Color glowColor;
  final VoidCallback onTap;
  final bool compact;
  final Widget? trailing;

  const _MainMenuCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.borderColor,
    required this.glowColor,
    required this.onTap,
    this.compact = false,
    this.trailing,
  });

  @override
  State<_MainMenuCard> createState() => _MainMenuCardState();
}

class _MainMenuCardState extends State<_MainMenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hover;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _glowAnim = Tween(begin: 1.0, end: 1.5)
        .animate(CurvedAnimation(parent: _hover, curve: Curves.easeOut));
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
      onTapUp: (_) { _hover.reverse(); widget.onTap(); },
      onTapCancel: () => _hover.reverse(),
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, __) => Container(
          padding: widget.compact
              ? const EdgeInsets.all(20)
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.borderColor.withValues(alpha: 0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.3 * _glowAnim.value),
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
                    Text(widget.label,
                        style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.textPrimary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(widget.description,
                        style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: widget.borderColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: widget.borderColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(widget.icon, color: widget.borderColor, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.label,
                              style: AppTheme.titleLarge.copyWith(
                                  color: widget.borderColor)),
                          const SizedBox(height: 4),
                          Text(widget.description, style: AppTheme.bodyMedium),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!
                    else Icon(Icons.chevron_right_rounded,
                        color: widget.borderColor.withValues(alpha: 0.5)),
                  ],
                ),
        ),
      ),
    );
  }
}
