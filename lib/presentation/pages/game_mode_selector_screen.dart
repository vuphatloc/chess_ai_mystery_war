import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/models/game_config.dart';
import '../../../domain/providers/user_provider.dart';
import '../../../domain/models/skin_registry.dart';
import '../../presentation/widgets/particle_background.dart';
import '../../presentation/widgets/common_widgets.dart';
import 'game_setup_screen.dart';

class GameModeSelectorScreen extends ConsumerStatefulWidget {
  const GameModeSelectorScreen({super.key});

  @override
  ConsumerState<GameModeSelectorScreen> createState() => _GameModeSelectorScreenState();
}

class _GameModeSelectorScreenState extends ConsumerState<GameModeSelectorScreen>
    with SingleTickerProviderStateMixin {
  GameMode _selectedMode = GameMode.normal;
  late AnimationController _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    super.dispose();
  }

  void _goToSetup() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => GameSetupScreen(mode: _selectedMode),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final settings = ref.watch(userSettingsProvider);
    final activeTheme = SkinRegistry.getTheme(settings.themeIndex);

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: AnimatedBuilder(
                  animation: _entryAnim,
                  builder: (_, child) => FadeTransition(
                    opacity: _entryAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                          .animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: _buildModeList(activeTheme),
                ),
              ),
              _buildStartButton(activeTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.get('select_mode'), style: AppTheme.labelSmall),
              Text(S.get('choose_battle'), style: AppTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeList(ThemeColors theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _ModeCard(
          mode: GameMode.normal,
          title: S.get('mode_normal'),
          subtitle: S.get('normal_subtitle'),
          description: S.get('normal_desc'),
          icon: '♟',
          color: theme.primary,
          features: [S.get('one_player'), S.get('two_players'), S.get('bot_difficulty')],
          isSelected: _selectedMode == GameMode.normal,
          onTap: () => setState(() => _selectedMode = GameMode.normal),
        ),
        const SizedBox(height: 14),
        _ModeCard(
          mode: GameMode.mystery,
          title: S.get('mode_mystery'),
          subtitle: S.get('mystery_subtitle'),
          description: S.get('mystery_desc'),
          icon: '🌫',
          color: theme.secondary,
          features: [S.get('hidden_identity'), S.get('fog_of_war'), S.get('double_blind')],
          isSelected: _selectedMode == GameMode.mystery,
          onTap: () => setState(() => _selectedMode = GameMode.mystery),
          badge: S.get('featured'),
        ),
        const SizedBox(height: 14),
        _ModeCard(
          mode: GameMode.champion,
          title: S.get('mode_champion'),
          subtitle: S.get('champion_subtitle'),
          description: S.get('champion_desc'),
          icon: '♛',
          color: AppTheme.gold,
          features: [S.get('champion_normal'), S.get('champion_mystery')],
          isSelected: _selectedMode == GameMode.champion,
          onTap: () => setState(() => _selectedMode = GameMode.champion),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStartButton(ThemeColors theme) {
    final colors = {
      GameMode.normal: theme.primary,
      GameMode.mystery: theme.secondary,
      GameMode.champion: AppTheme.gold,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: NeonButton(
        label: S.get('begin_match'),
        icon: Icons.arrow_forward_rounded,
        color: colors[_selectedMode]!,
        isWide: true,
        height: 60,
        onTap: _goToSetup,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final GameMode mode;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final Color color;
  final List<String> features;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _ModeCard({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.textMuted.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 20, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: AppTheme.titleLarge.copyWith(
                                  color: isSelected ? color : AppTheme.textPrimary, fontSize: 18)),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withOpacity(0.5)),
                              ),
                              child: Text(badge!,
                                  style: AppTheme.labelSmall.copyWith(color: color, fontSize: 9)),
                            ),
                          ],
                        ],
                      ),
                      Text(subtitle, style: AppTheme.bodyMedium.copyWith(color: color.withOpacity(0.7))),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(color: isSelected ? color : AppTheme.textMuted, width: 2),
                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: AppTheme.bodyMedium.copyWith(fontSize: 13)),
            if (isSelected) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features.map((f) => _FeatureChip(label: f, color: color)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FeatureChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(color: color.withOpacity(0.9), fontSize: 10),
      ),
    );
  }
}
