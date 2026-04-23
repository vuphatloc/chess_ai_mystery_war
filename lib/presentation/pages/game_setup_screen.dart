import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/models/game_config.dart';
import '../widgets/particle_background.dart';
import '../widgets/common_widgets.dart';
import 'game_screen.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  const GameSetupScreen({super.key, required this.mode});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  // -- State --
  PlayerCount _playerCount = PlayerCount.one;
  BotDifficulty _botDifficulty = BotDifficulty.intermediate;
  TimeControl _timeControl = TimeControl.unlimited;
  MysterySubType _mysterySubType = MysterySubType.hiddenIdentity;
  ChampionSubType _championSubType = ChampionSubType.normal;
  ChampionSession _championSession = ChampionSession.newCampaign;
  // Simulate a saved campaign flag
  final bool _hasSavedCampaign = false;

  Color get _modeColor {
    switch (widget.mode) {
      case GameMode.normal: return AppTheme.neonCyan;
      case GameMode.mystery: return AppTheme.neonPurple;
      case GameMode.champion: return AppTheme.gold;
    }
  }

  void _startGame() {
    final config = GameConfig(
      mode: widget.mode,
      playerCount: widget.mode == GameMode.champion ? PlayerCount.one : _playerCount,
      botDifficulty: _botDifficulty,
      timeControl: _timeControl,
      mysterySubType: widget.mode == GameMode.mystery ? _mysterySubType : null,
      championSubType: widget.mode == GameMode.champion ? _championSubType : null,
      championSession: widget.mode == GameMode.champion ? _championSession : null,
    );
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, anim, __) => GameScreen(config: config),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Watch language to rebuild on change
    ref.watch(languageProvider);
    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 8),
                    if (widget.mode == GameMode.champion) ...[
                      _buildSection(S.get('champion_session'), _buildChampionSession()),
                      const SizedBox(height: 20),
                      _buildSection(S.get('champion_type'), _buildChampionType()),
                    ] else ...[
                      _buildSection(S.get('players'), _buildPlayerCount()),
                      if (_playerCount == PlayerCount.one) ...[
                        const SizedBox(height: 20),
                        _buildSection(S.get('bot_difficulty'), _buildBotDifficulty()),
                      ],
                      if (widget.mode == GameMode.mystery) ...[
                        const SizedBox(height: 20),
                        _buildSection(S.get('mystery_type'), _buildMysteryTypes()),
                      ],
                    ],
                    const SizedBox(height: 20),
                    _buildSection(S.get('time_control'), _buildTimeControl()),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              Text(S.get('game_setup'), style: AppTheme.labelSmall),
              Text(S.get('configure_match'), style: AppTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  // ── Player Count ──────────────────────────────────────────────────────────

  Widget _buildPlayerCount() {
    return Row(
      children: [
        Expanded(
          child: _ToggleCard(
            icon: Icons.person_rounded,
            label: S.get('one_player'),
            sublabel: S.get('vs_ai'),
            color: _modeColor,
            isSelected: _playerCount == PlayerCount.one,
            onTap: () => setState(() => _playerCount = PlayerCount.one),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleCard(
            icon: Icons.people_rounded,
            label: S.get('two_players'),
            sublabel: S.get('vs_friend'),
            color: _modeColor,
            isSelected: _playerCount == PlayerCount.two,
            onTap: () => setState(() => _playerCount = PlayerCount.two),
          ),
        ),
      ],
    );
  }

  // ── Bot Difficulty ─────────────────────────────────────────────────────────

  Widget _buildBotDifficulty() {
    final difficulties = BotDifficulty.values;
    final labelKeys = {
      BotDifficulty.beginner: 'diff_beginner',
      BotDifficulty.novice: 'diff_novice',
      BotDifficulty.intermediate: 'diff_intermediate',
      BotDifficulty.advanced: 'diff_advanced',
      BotDifficulty.expert: 'diff_expert',
      BotDifficulty.master: 'diff_master',
      BotDifficulty.grandmaster: 'diff_grandmaster',
    };
    final colors = [
      Colors.green,
      Colors.lightGreen,
      AppTheme.neonCyan,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      AppTheme.neonPurple,
    ];

    return Column(
      children: [
        // Slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(borderRadius: 14, borderColor: _modeColor.withValues(alpha: 0.3)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.get(labelKeys[_botDifficulty]!),
                      style: AppTheme.titleMedium.copyWith(color: colors[_botDifficulty.index], fontSize: 15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors[_botDifficulty.index].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors[_botDifficulty.index].withValues(alpha: 0.4)),
                    ),
                    child: Text(_botDifficulty.eloLabel,
                        style: AppTheme.labelSmall.copyWith(color: colors[_botDifficulty.index])),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colors[_botDifficulty.index],
                  thumbColor: colors[_botDifficulty.index],
                  overlayColor: colors[_botDifficulty.index].withValues(alpha: 0.2),
                  inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.3),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _botDifficulty.index.toDouble(),
                  min: 0,
                  max: (difficulties.length - 1).toDouble(),
                  divisions: difficulties.length - 1,
                  onChanged: (v) => setState(() => _botDifficulty = difficulties[v.round()]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.get('diff_beginner'),
                      style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted, fontSize: 9)),
                  Text(S.get('diff_grandmaster'),
                      style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted, fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Time Control ──────────────────────────────────────────────────────────

  Widget _buildTimeControl() {
    final options = TimeControl.values;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((tc) {
        final isSelected = _timeControl == tc;
        final label = tc.isUnlimited
            ? S.get('unlimited')
            : tc.label(S.get('min'), S.get('increment'));
        return GestureDetector(
          onTap: () => setState(() => _timeControl = tc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _modeColor.withValues(alpha: 0.15) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _modeColor : AppTheme.textMuted.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: _modeColor.withValues(alpha: 0.3), blurRadius: 10)]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tc.isUnlimited ? Icons.all_inclusive_rounded : Icons.timer_rounded,
                  color: isSelected ? _modeColor : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTheme.labelSmall.copyWith(
                    color: isSelected ? _modeColor : AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Mystery Sub-types ──────────────────────────────────────────────────────

  Widget _buildMysteryTypes() {
    final types = [
      _MysteryTypeInfo(
        type: MysterySubType.hiddenIdentity,
        icon: '🂠',
        titleKey: 'hidden_identity',
        descKey: 'hidden_identity_desc',
        color: AppTheme.neonPurple,
      ),
      _MysteryTypeInfo(
        type: MysterySubType.fogOfWar,
        icon: '🌫',
        titleKey: 'fog_of_war',
        descKey: 'fog_of_war_desc',
        color: Colors.blueGrey,
      ),
      _MysteryTypeInfo(
        type: MysterySubType.blindfold,
        icon: '🙈',
        titleKey: 'blindfold',
        descKey: 'blindfold_desc',
        color: Colors.deepOrange,
      ),
      _MysteryTypeInfo(
        type: MysterySubType.doubleBlind,
        icon: '💀',
        titleKey: 'double_blind',
        descKey: 'double_blind_desc',
        color: Colors.red,
      ),
    ];
    return Column(
      children: types.map((info) {
        final isSelected = _mysterySubType == info.type;
        final isFeatured = info.type == MysterySubType.hiddenIdentity;
        return GestureDetector(
          onTap: () => setState(() => _mysterySubType = info.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? info.color.withValues(alpha: 0.1) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? info.color : AppTheme.textMuted.withValues(alpha: 0.25),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: info.color.withValues(alpha: 0.25), blurRadius: 12)]
                  : [],
            ),
            child: Row(
              children: [
                Text(info.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(S.get(info.titleKey),
                                style: AppTheme.titleMedium.copyWith(
                                    color: isSelected ? info.color : AppTheme.textPrimary,
                                    fontSize: 13)),
                          ),
                          if (isFeatured) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.6)),
                              ),
                              child: Text(S.get('featured'),
                                  style: AppTheme.labelSmall.copyWith(
                                      color: AppTheme.gold, fontSize: 8)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(S.get(info.descKey),
                          style: AppTheme.bodyMedium.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? info.color : Colors.transparent,
                    border: Border.all(
                        color: isSelected ? info.color : AppTheme.textMuted, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 12)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Champion Session ───────────────────────────────────────────────────────

  Widget _buildChampionSession() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(S.get('champion_only_1p'),
                    style: AppTheme.bodyMedium.copyWith(fontSize: 12, color: AppTheme.gold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ToggleCard(
                icon: Icons.add_circle_outline_rounded,
                label: S.get('new_campaign'),
                sublabel: '',
                color: AppTheme.gold,
                isSelected: _championSession == ChampionSession.newCampaign,
                onTap: () => setState(() => _championSession = ChampionSession.newCampaign),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToggleCard(
                icon: Icons.play_circle_outline_rounded,
                label: S.get('continue_campaign'),
                sublabel: _hasSavedCampaign ? '' : S.get('no_save_found'),
                color: _hasSavedCampaign ? AppTheme.gold : AppTheme.textMuted,
                isSelected: _championSession == ChampionSession.continueCampaign,
                onTap: _hasSavedCampaign
                    ? () => setState(() => _championSession = ChampionSession.continueCampaign)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChampionType() {
    return Row(
      children: [
        Expanded(
          child: _ToggleCard(
            icon: Icons.shield_rounded,
            label: S.get('champion_normal'),
            sublabel: S.get('champion_normal_desc'),
            color: AppTheme.gold,
            isSelected: _championSubType == ChampionSubType.normal,
            onTap: () => setState(() => _championSubType = ChampionSubType.normal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleCard(
            icon: Icons.auto_awesome_rounded,
            label: S.get('champion_mystery'),
            sublabel: S.get('champion_mystery_desc'),
            color: AppTheme.neonPurple,
            isSelected: _championSubType == ChampionSubType.mystery,
            onTap: () => setState(() => _championSubType = ChampionSubType.mystery),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: NeonButton(
        label: S.get('start_battle'),
        icon: Icons.play_arrow_rounded,
        color: _modeColor,
        isWide: true,
        height: 60,
        onTap: _startGame,
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTheme.labelSmall),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.glassBorder, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ToggleCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : disabled
                    ? AppTheme.textMuted.withValues(alpha: 0.1)
                    : AppTheme.textMuted.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: isSelected
                    ? color
                    : disabled
                        ? AppTheme.textMuted.withValues(alpha: 0.3)
                        : AppTheme.textSecondary,
                size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTheme.titleMedium.copyWith(
                color: isSelected
                    ? color
                    : disabled
                        ? AppTheme.textMuted.withValues(alpha: 0.4)
                        : AppTheme.textPrimary,
                fontSize: 13,
              ),
              maxLines: 2,
            ),
            if (sublabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: AppTheme.bodyMedium.copyWith(fontSize: 10),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MysteryTypeInfo {
  final MysterySubType type;
  final String icon;
  final String titleKey;
  final String descKey;
  final Color color;
  const _MysteryTypeInfo({
    required this.type,
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.color,
  });
}
