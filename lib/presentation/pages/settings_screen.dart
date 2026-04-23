import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../presentation/widgets/particle_background.dart';
import '../../presentation/widgets/common_widgets.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _hintsEnabled = true;
  int _selectedTheme = 0;

  final List<_ThemeOption> _themes = [
    _ThemeOption('Cyber Neon', AppTheme.neonCyan, AppTheme.neonPurple),
    _ThemeOption('Golden Knight', AppTheme.gold, Colors.orange),
    _ThemeOption('Blood Moon', Colors.red, Colors.deepOrange),
    _ThemeOption('Arctic Ice', Colors.lightBlueAccent, Colors.cyanAccent),
  ];

  @override
  Widget build(BuildContext context) {
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
                    _buildSectionLabel('AUDIO'),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.music_note_rounded,
                      title: 'Background Music',
                      description: 'Atmospheric game soundtrack',
                      value: _musicEnabled,
                      color: AppTheme.neonCyan,
                      onChanged: (v) => setState(() => _musicEnabled = v),
                    ),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound Effects',
                      description: 'Piece moves, captures, check alerts',
                      value: _sfxEnabled,
                      color: AppTheme.neonCyan,
                      onChanged: (v) => setState(() => _sfxEnabled = v),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('GAMEPLAY'),
                    const SizedBox(height: 10),
                    _buildToggleTile(
                      icon: Icons.lightbulb_rounded,
                      title: 'Move Hints',
                      description: 'Highlight best moves to help beginners',
                      value: _hintsEnabled,
                      color: AppTheme.neonPurple,
                      onChanged: (v) => setState(() => _hintsEnabled = v),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('APP THEME'),
                    const SizedBox(height: 12),
                    _buildThemeSelector(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('TUTORIAL'),
                    const SizedBox(height: 10),
                    _buildTutorialCard(context),
                    const SizedBox(height: 32),
                    _buildAppInfo(),
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
              Text('CONFIGURATION', style: AppTheme.labelSmall),
              Text('Settings', style: AppTheme.titleLarge),
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
              gradient: LinearGradient(
                colors: [AppTheme.glassBorder, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
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
        color: value ? color.withOpacity(0.05) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withOpacity(0.4) : AppTheme.textMuted.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: value ? color.withOpacity(0.15) : AppTheme.textMuted.withOpacity(0.1),
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
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
            inactiveTrackColor: AppTheme.textMuted.withOpacity(0.2),
            inactiveThumbColor: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(_themes.length, (i) {
        final theme = _themes[i];
        final isSelected = _selectedTheme == i;
        return GestureDetector(
          onTap: () => setState(() => _selectedTheme = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [theme.primary.withOpacity(0.2), theme.secondary.withOpacity(0.1)])
                  : null,
              color: isSelected ? null : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.primary : AppTheme.textMuted.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [BoxShadow(color: theme.primary.withOpacity(0.3), blurRadius: 12)] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
                    boxShadow: isSelected ? [BoxShadow(color: theme.primary, blurRadius: 4)] : [],
                  ),
                ),
                const SizedBox(width: 8),
                Text(theme.name,
                    style: AppTheme.bodyMedium.copyWith(
                        color: isSelected ? theme.primary : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTutorialCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TutorialScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00200A), Color(0xFF001209)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 12)],
        ),
        child: Row(
          children: [
            const Text('🎓', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chess for Beginners',
                      style: AppTheme.titleMedium.copyWith(color: Colors.greenAccent)),
                  const SizedBox(height: 4),
                  Text('Learn piece movement, strategy & Mystery Mode rules.',
                      style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.greenAccent.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          const Text('♞', style: TextStyle(fontSize: 28,
              shadows: [Shadow(color: AppTheme.neonCyan, blurRadius: 12)])),
          const SizedBox(height: 6),
          Text('Chess AI: Mystery War', style: AppTheme.titleMedium),
          const SizedBox(height: 4),
          Text('v1.0.0 • AI-Powered', style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _ThemeOption {
  final String name;
  final Color primary;
  final Color secondary;
  _ThemeOption(this.name, this.primary, this.secondary);
}
