import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/models/skin_registry.dart';
import '../../../domain/providers/user_provider.dart';
import '../../../domain/services/audio_service.dart';
import '../../presentation/widgets/particle_background.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final settings = ref.watch(userSettingsProvider);
    final themes = SkinRegistry.themes;
    final activeTheme = SkinRegistry.getTheme(settings.themeIndex);

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),

                    // ── Audio ──────────────────────────────────────────────
                    _buildSectionLabel(S.get('audio')),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.music_note_rounded,
                      title: S.get('bg_music'),
                      description: S.get('bg_music_desc'),
                      value: settings.musicEnabled,
                      color: activeTheme.primary,
                      onChanged: (v) {
                        ref.read(userSettingsProvider.notifier)
                            .update(settings.copyWith(musicEnabled: v));
                        AudioService().setMusicEnabled(v);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.volume_up_rounded,
                      title: S.get('sfx'),
                      description: S.get('sfx_desc'),
                      value: settings.sfxEnabled,
                      color: activeTheme.primary,
                      onChanged: (v) {
                        ref.read(userSettingsProvider.notifier)
                            .update(settings.copyWith(sfxEnabled: v));
                        AudioService().setSfxEnabled(v);
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Gameplay ───────────────────────────────────────────
                    _buildSectionLabel(S.get('gameplay')),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.lightbulb_rounded,
                      title: S.get('move_hints'),
                      description: S.get('move_hints_desc'),
                      value: settings.hintsEnabled,
                      color: activeTheme.secondary,
                      onChanged: (v) {
                        ref.read(userSettingsProvider.notifier)
                            .update(settings.copyWith(hintsEnabled: v));
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Language ───────────────────────────────────────────
                    _buildSectionLabel(S.get('language')),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(settings.language, activeTheme),

                    const SizedBox(height: 24),

                    // ── Theme ──────────────────────────────────────────────
                    _buildSectionLabel(S.get('app_theme')),
                    const SizedBox(height: 4),
                    Text(S.get('theme_desc'), style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
                    const SizedBox(height: 10),
                    _buildThemeSelector(themes, settings.themeIndex),

                    const SizedBox(height: 24),

                    // ── Tutorial ───────────────────────────────────────────
                    _buildSectionLabel(S.get('tutorial_section')),
                    const SizedBox(height: 10),
                    _buildTutorialCard(context),

                    const SizedBox(height: 32),
                    _buildAppInfo(activeTheme),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
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
              Text(S.get('configuration'), style: AppTheme.labelSmall),
              Text(S.get('settings'), style: AppTheme.titleLarge),
            ],
          ),
          const Spacer(),
          // Auto-save indicator
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                  boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 6),
              Text(S.get('auto_saved'),
                  style: AppTheme.labelSmall.copyWith(color: Colors.greenAccent, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Text(label, style: AppTheme.labelSmall),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.glassBorder, Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(String currentLang, ThemeColors theme) {
    final languages = AppStrings.availableLanguages;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: languages.map((lang) {
        final isSelected = currentLang == lang['code'];
        return GestureDetector(
          onTap: () {
            final s = ref.read(userSettingsProvider);
            ref.read(userSettingsProvider.notifier)
                .update(s.copyWith(language: lang['code']));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? theme.primary.withValues(alpha: 0.1) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.primary : AppTheme.textMuted.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: theme.primary.withValues(alpha: 0.25), blurRadius: 10)]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(lang['name']!,
                    style: AppTheme.bodyMedium.copyWith(
                        color: isSelected ? theme.primary : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemeSelector(List<ThemeColors> themes, int selectedIndex) {
    return Column(
      children: themes.asMap().entries.map((entry) {
        final i = entry.key;
        final theme = entry.value;
        final isSelected = selectedIndex == i;
        return GestureDetector(
          onTap: () {
            final s = ref.read(userSettingsProvider);
            ref.read(userSettingsProvider.notifier).update(s.copyWith(themeIndex: i));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [
                      theme.primary.withValues(alpha: 0.15),
                      theme.secondary.withValues(alpha: 0.08),
                    ])
                  : null,
              color: isSelected ? null : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? theme.primary : AppTheme.textMuted.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 14)]
                  : [],
            ),
            child: Row(
              children: [
                // Color swatch
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.primary, theme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: theme.primary, blurRadius: 8)]
                        : [],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(theme.name,
                          style: AppTheme.titleMedium.copyWith(
                              color: isSelected ? theme.primary : AppTheme.textPrimary,
                              fontSize: 14)),
                      // Board preview colors
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12, height: 8,
                            decoration: BoxDecoration(
                              color: theme.boardLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Container(
                            width: 12, height: 8,
                            decoration: BoxDecoration(
                              color: theme.boardDark,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(S.get('board_preview'),
                              style: AppTheme.bodyMedium.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.05) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.4) : AppTheme.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: value ? color.withValues(alpha: 0.15) : AppTheme.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: value ? color : AppTheme.textMuted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleMedium.copyWith(
                    color: value ? AppTheme.textPrimary : AppTheme.textSecondary)),
                Text(description, style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.2),
            inactiveThumbColor: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TutorialScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00200A), Color(0xFF001209)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
          boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.1), blurRadius: 12)],
        ),
        child: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.get('chess_beginners'),
                      style: AppTheme.titleMedium.copyWith(color: Colors.greenAccent)),
                  const SizedBox(height: 4),
                  Text(S.get('chess_beginners_desc'),
                      style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.greenAccent.withValues(alpha: 0.6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo(ThemeColors theme) {
    return Center(
      child: Column(
        children: [
          Text('♞', style: TextStyle(fontSize: 28,
              shadows: [Shadow(color: theme.primary, blurRadius: 12)])),
          const SizedBox(height: 6),
          Text('Chess AI: Mystery War', style: AppTheme.titleMedium),
          const SizedBox(height: 4),
          Text('v1.0.0 • AI-Powered', style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
