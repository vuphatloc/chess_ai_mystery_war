import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/models/skin_registry.dart';
import '../../../domain/providers/user_provider.dart';
import '../../presentation/widgets/particle_background.dart';
import '../../presentation/widgets/common_widgets.dart';
import '../../presentation/widgets/chess_piece_widget.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() => _selectedTab = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final gold = ref.watch(goldProvider);

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, gold),
              const SizedBox(height: 4),
              _buildTabBar(),
              const SizedBox(height: 4),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPieceSkins(),
                    _buildBoardSkins(),
                    _buildEarnGold(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int gold) {
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
              Text(S.get('marketplace'), style: AppTheme.labelSmall),
              Text(S.get('store'), style: AppTheme.titleLarge),
            ],
          ),
          const Spacer(),
          GoldBadge(amount: gold),
        ],
      ),
    );
  }

  // ── Custom Tab Bar (full background when selected) ─────────────────────
  Widget _buildTabBar() {
    final tabs = [S.get('pieces_tab'), S.get('boards_tab'), S.get('earn_tab')];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(i);
                setState(() => _selectedTab = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.cyanPurpleGradient : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.3), blurRadius: 8)]
                      : [],
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTheme.labelSmall.copyWith(
                      color: isSelected ? Colors.black : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  // ── Piece Skins ────────────────────────────────────────────────────────

  Widget _buildPieceSkins() {
    final owned = ref.watch(ownedSkinsProvider);
    final activePieceSkin = ref.watch(activePieceSkinProvider);
    final gold = ref.watch(goldProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: SkinRegistry.pieceSkins.length,
      itemBuilder: (_, i) {
        final skin = SkinRegistry.pieceSkins[i];
        final isOwned = owned.contains(skin.id);
        final isActive = activePieceSkin == skin.id;
        final canAfford = gold >= skin.price;
        return _SkinCard(
          name: skin.name,
          price: skin.price,
          isOwned: isOwned,
          isActive: isActive,
          canAfford: canAfford,
          isFree: skin.price == 0,
          preview: PieceSkinPreview(skin: skin, size: 60),
          glowColor: skin.whiteGlow,
          onBuy: () => _confirmPurchase(context, skin.id, skin.name, skin.price, isPiece: true),
          onEquip: () {
            final settings = ref.read(userSettingsProvider);
            ref.read(userSettingsProvider.notifier)
                .update(settings.copyWith(activePieceSkinId: skin.id));
          },
        );
      },
    );
  }

  // ── Board Skins ────────────────────────────────────────────────────────

  Widget _buildBoardSkins() {
    final owned = ref.watch(ownedSkinsProvider);
    final activeBoardSkin = ref.watch(activeBoardSkinProvider);
    final gold = ref.watch(goldProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: SkinRegistry.boardSkins.length,
      itemBuilder: (_, i) {
        final skin = SkinRegistry.boardSkins[i];
        final isOwned = owned.contains(skin.id);
        final isActive = activeBoardSkin == skin.id;
        final canAfford = gold >= skin.price;
        return _SkinCard(
          name: skin.name,
          price: skin.price,
          isOwned: isOwned,
          isActive: isActive,
          canAfford: canAfford,
          isFree: skin.price == 0,
          preview: _BoardSkinPreview(skin: skin),
          glowColor: skin.highlightTint ?? AppTheme.neonCyan,
          onBuy: () => _confirmPurchase(context, skin.id, skin.name, skin.price, isPiece: false),
          onEquip: () {
            final settings = ref.read(userSettingsProvider);
            ref.read(userSettingsProvider.notifier)
                .update(settings.copyWith(activeBoardSkinId: skin.id));
          },
        );
      },
    );
  }

  // ── Earn Gold ──────────────────────────────────────────────────────────

  Widget _buildEarnGold() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Watch Ad — main featured card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.neonBorderDecoration(color: AppTheme.gold),
          child: Column(
            children: [
              const Text('⬡', style: TextStyle(fontSize: 56, color: AppTheme.gold)),
              const SizedBox(height: 12),
              Text(S.get('watch_ad'),
                  style: AppTheme.titleLarge.copyWith(color: AppTheme.gold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(S.get('watch_ad_desc'),
                  style: AppTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              NeonButton(
                label: S.get('watch_ad'),
                icon: Icons.play_circle_outline_rounded,
                color: AppTheme.gold,
                isWide: true,
                onTap: () => ref.read(goldProvider.notifier).add(100),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Daily Login
        _EarnTile(
          icon: Icons.calendar_today_rounded,
          title: S.get('daily_login'),
          description: S.get('daily_login_desc'),
          reward: '+25 ${S.get("gold")}',
          color: AppTheme.neonPurple,
        ),
      ],
    );
  }

  // ── Confirm Purchase Dialog ────────────────────────────────────────────

  Future<void> _confirmPurchase(
      BuildContext context, String id, String name, int price,
      {required bool isPiece}) async {
    final gold = ref.read(goldProvider);
    final canAfford = gold >= price;
    final remaining = gold - price;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.5)),
        ),
        title: Text(
          S.get('confirm_purchase'),
          style: AppTheme.titleLarge.copyWith(color: AppTheme.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.get("confirm_buy_msg")} "$name" ${S.get("for")} $price ${S.get("gold")}?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Gold info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canAfford
                    ? AppTheme.gold.withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: canAfford
                        ? AppTheme.gold.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _GoldRow('${S.get("gold")}:', gold, AppTheme.gold),
                  _GoldRow('${S.get("for")}:', -price, Colors.red),
                  const Divider(color: AppTheme.glassBorder, height: 12),
                  _GoldRow('${S.get("after_purchase")}:', remaining, canAfford ? Colors.greenAccent : Colors.red),
                ],
              ),
            ),
            if (!canAfford) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(S.get('insufficient_gold_msg'),
                      style: AppTheme.bodyMedium.copyWith(color: Colors.red, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.get('cancel'), style: AppTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: canAfford
                ? () async {
                    Navigator.pop(ctx);
                    final success = await ref
                        .read(ownedSkinsProvider.notifier)
                        .purchase(id, price, ref.read(goldProvider.notifier));
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name ${S.get("owned")}! ✓'),
                          backgroundColor: AppTheme.gold.withValues(alpha: 0.9),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? AppTheme.gold : AppTheme.textMuted,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(S.get('confirm'),
                style: AppTheme.titleMedium.copyWith(color: Colors.black, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Skin Card ───────────────────────────────────────────────────────────────

class _SkinCard extends StatelessWidget {
  final String name;
  final int price;
  final bool isOwned;
  final bool isActive;
  final bool canAfford;
  final bool isFree;
  final Widget preview;
  final Color glowColor;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  const _SkinCard({
    required this.name,
    required this.price,
    required this.isOwned,
    required this.isActive,
    required this.canAfford,
    required this.isFree,
    required this.preview,
    required this.glowColor,
    required this.onBuy,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isActive
            ? glowColor.withValues(alpha: 0.1)
            : isOwned
                ? glowColor.withValues(alpha: 0.05)
                : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? glowColor
              : isOwned
                  ? glowColor.withValues(alpha: 0.4)
                  : AppTheme.textMuted.withValues(alpha: 0.25),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: glowColor.withValues(alpha: 0.35), blurRadius: 16)]
            : isOwned
                ? [BoxShadow(color: glowColor.withValues(alpha: 0.15), blurRadius: 8)]
                : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview
            SizedBox(width: 64, height: 64, child: preview),
            const SizedBox(height: 10),
            // Name
            Text(
              name,
              style: AppTheme.titleMedium.copyWith(
                color: isActive ? glowColor : AppTheme.textPrimary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Status badge / action
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: glowColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: glowColor.withValues(alpha: 0.5)),
                ),
                child: Text(S.get('equipped'),
                    style: AppTheme.labelSmall.copyWith(color: glowColor, fontSize: 9)),
              )
            else if (isOwned)
              GestureDetector(
                onTap: onEquip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: glowColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: glowColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(S.get('equip'),
                      style: AppTheme.labelSmall.copyWith(color: glowColor, fontSize: 9)),
                ),
              )
            else if (isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('FREE',
                    style: AppTheme.labelSmall.copyWith(color: Colors.greenAccent, fontSize: 9)),
              )
            else
              GestureDetector(
                onTap: canAfford ? onBuy : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? AppTheme.gold.withValues(alpha: 0.15)
                        : AppTheme.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: canAfford
                            ? AppTheme.gold.withValues(alpha: 0.5)
                            : AppTheme.textMuted.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⬡ ',
                          style: TextStyle(
                              color: canAfford ? AppTheme.gold : AppTheme.textMuted,
                              fontSize: 11)),
                      Text('$price',
                          style: AppTheme.labelSmall.copyWith(
                              color: canAfford ? AppTheme.gold : AppTheme.textMuted,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Board Skin Preview ──────────────────────────────────────────────────────

class _BoardSkinPreview extends StatelessWidget {
  final BoardSkinDef skin;
  const _BoardSkinPreview({required this.skin});

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
          final row = i ~/ 4;
          final col = i % 4;
          final isDark = (row + col) % 2 == 1;
          return Container(
            color: isDark ? skin.darkSquare : skin.lightSquare,
          );
        },
      ),
    );
  }
}

// ── Earn Tile ───────────────────────────────────────────────────────────────

class _EarnTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String reward;
  final Color color;
  const _EarnTile({
    required this.icon, required this.title, required this.description,
    required this.reward, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary)),
                Text(description, style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
            ),
            child: Text(reward, style: AppTheme.labelSmall.copyWith(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }
}

// ── Gold Row helper ─────────────────────────────────────────────────────────

class _GoldRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  const _GoldRow(this.label, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMedium.copyWith(fontSize: 12)),
          Row(
            children: [
              Text('⬡ ', style: TextStyle(color: color, fontSize: 13)),
              Text(
                amount >= 0 ? '$amount' : '$amount',
                style: AppTheme.titleMedium.copyWith(color: color, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
