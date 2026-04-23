import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/models/skin_registry.dart';
import '../../../domain/providers/user_provider.dart';
import '../../presentation/widgets/particle_background.dart';
import '../../presentation/widgets/chess_piece_widget.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final owned = ref.watch(ownedSkinsProvider);
    final activePiece = ref.watch(activePieceSkinProvider);
    final activeBoard = ref.watch(activeBoardSkinProvider);
    final settings = ref.watch(userSettingsProvider);
    final activeTheme = SkinRegistry.getTheme(settings.themeIndex);

    final ownedPieces = SkinRegistry.pieceSkins.where((s) => owned.contains(s.id)).toList();
    final ownedBoards = SkinRegistry.boardSkins.where((s) => owned.contains(s.id)).toList();

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 4),
              _buildTabBar(activeTheme),
              const SizedBox(height: 8),
              Expanded(
                child: _tab == 0
                    ? _buildPieceGrid(ownedPieces, activePiece, activeTheme)
                    : _buildBoardGrid(ownedBoards, activeBoard, activeTheme),
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
              Text(S.get('inventory'), style: AppTheme.labelSmall),
              Text(S.get('my_collection'), style: AppTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeColors theme) {
    final tabs = [S.get('piece_skins'), S.get('board_skins')];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final isSelected = _tab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [theme.primary, theme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: AppTheme.labelSmall.copyWith(
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieceGrid(List<PieceSkinDef> skins, String activeSkinId, ThemeColors theme) {
    if (skins.isEmpty) return _buildEmpty();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85,
      ),
      itemCount: skins.length,
      itemBuilder: (_, i) {
        final skin = skins[i];
        final isActive = skin.id == activeSkinId;
        return _InventoryCard(
          name: skin.name,
          isActive: isActive,
          glowColor: skin.whiteGlow,
          theme: theme,
          preview: PieceSkinPreview(skin: skin, size: 64),
          onEquip: () {
            final settings = ref.read(userSettingsProvider);
            ref.read(userSettingsProvider.notifier)
                .update(settings.copyWith(activePieceSkinId: skin.id));
          },
        );
      },
    );
  }

  Widget _buildBoardGrid(List<BoardSkinDef> skins, String activeSkinId, ThemeColors theme) {
    if (skins.isEmpty) return _buildEmpty();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85,
      ),
      itemCount: skins.length,
      itemBuilder: (_, i) {
        final skin = skins[i];
        final isActive = skin.id == activeSkinId;
        final glowColor = skin.highlightTint ?? theme.primary;
        return _InventoryCard(
          name: skin.name,
          isActive: isActive,
          glowColor: glowColor,
          theme: theme,
          preview: _BoardMiniPreview(skin: skin),
          onEquip: () {
            final settings = ref.read(userSettingsProvider);
            ref.read(userSettingsProvider.notifier)
                .update(settings.copyWith(activeBoardSkinId: skin.id));
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📦', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(S.get('no_items'), style: AppTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final Color glowColor;
  final Widget preview;
  final ThemeColors theme;
  final VoidCallback onEquip;

  const _InventoryCard({
    required this.name, required this.isActive, required this.glowColor,
    required this.theme, required this.preview, required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onEquip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? glowColor.withValues(alpha: 0.12) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? glowColor : AppTheme.textMuted.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: glowColor.withValues(alpha: 0.35), blurRadius: 18)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 64, height: 64, child: preview),
            const SizedBox(height: 10),
            Text(
              name,
              style: AppTheme.titleMedium.copyWith(
                color: isActive ? glowColor : AppTheme.textPrimary, fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? glowColor.withValues(alpha: 0.2)
                    : theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive
                        ? glowColor
                        : theme.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                isActive ? S.get('equipped') : S.get('equip'),
                style: AppTheme.labelSmall.copyWith(
                    color: isActive ? glowColor : theme.primary, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardMiniPreview extends StatelessWidget {
  final BoardSkinDef skin;
  const _BoardMiniPreview({required this.skin});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
        itemCount: 16,
        itemBuilder: (_, i) {
          final r = i ~/ 4;
          final c = i % 4;
          return Container(color: (r + c) % 2 == 1 ? skin.darkSquare : skin.lightSquare);
        },
      ),
    );
  }
}
