import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../presentation/widgets/particle_background.dart';
import '../../presentation/widgets/common_widgets.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _gold = 1250;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
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
              Text('MARKETPLACE', style: AppTheme.labelSmall),
              Text('Store', style: AppTheme.titleLarge),
            ],
          ),
          const Spacer(),
          GoldBadge(amount: _gold),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.cyanPurpleGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: AppTheme.labelSmall.copyWith(fontSize: 11),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'PIECES'),
          Tab(text: 'BOARDS'),
          Tab(text: 'EARN GOLD'),
        ],
      ),
    );
  }

  Widget _buildPieceSkins() {
    final skins = [
      _SkinItem(name: 'Cyber Neon', icon: '♞', price: 500, owned: true, color: AppTheme.neonCyan),
      _SkinItem(name: 'Classic Wood', icon: '♞', price: 300, owned: false, color: const Color(0xFF8B6914)),
      _SkinItem(name: 'Holographic', icon: '♞', price: 800, owned: false, color: AppTheme.neonPurple),
      _SkinItem(name: 'Fire Elemental', icon: '♞', price: 1200, owned: false, color: Colors.orange),
      _SkinItem(name: 'Ice Crystal', icon: '♞', price: 1000, owned: false, color: Colors.lightBlueAccent),
      _SkinItem(name: 'Dark Matter', icon: '♞', price: 1500, owned: false, color: AppTheme.neonPurple),
    ];
    return _SkinGrid(skins: skins, gold: _gold, onBuy: (item) {
      if (_gold >= item.price) setState(() => _gold -= item.price);
    });
  }

  Widget _buildBoardSkins() {
    final skins = [
      _SkinItem(name: 'Deep Space', icon: '🌌', price: 800, owned: true, color: AppTheme.neonCyan),
      _SkinItem(name: 'Marble Palace', icon: '🏛', price: 600, owned: false, color: Colors.grey),
      _SkinItem(name: 'Cyberpunk City', icon: '🌆', price: 1000, owned: false, color: AppTheme.neonPurple),
      _SkinItem(name: 'Enchanted Forest', icon: '🌲', price: 700, owned: false, color: Colors.green),
    ];
    return _SkinGrid(skins: skins, gold: _gold, onBuy: (item) {
      if (_gold >= item.price) setState(() => _gold -= item.price);
    });
  }

  Widget _buildEarnGold() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.neonBorderDecoration(color: AppTheme.gold),
          child: Column(
            children: [
              const Text('⬡', style: TextStyle(fontSize: 56, color: AppTheme.gold)),
              const SizedBox(height: 12),
              Text('Watch Ad · Earn Gold', style: AppTheme.titleLarge.copyWith(color: AppTheme.gold)),
              const SizedBox(height: 8),
              Text('Watch a short video and earn 100 Gold instantly.',
                  style: AppTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              NeonButton(
                label: 'WATCH AD (+100 Gold)',
                icon: Icons.play_circle_outline_rounded,
                color: AppTheme.gold,
                isWide: true,
                onTap: () => setState(() => _gold += 100),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EarnTile(
          icon: Icons.emoji_events_rounded,
          title: 'Win a Game',
          description: 'Earn 50 Gold per victory in any mode.',
          reward: '+50 Gold',
          color: AppTheme.neonCyan,
        ),
        const SizedBox(height: 12),
        _EarnTile(
          icon: Icons.star_rounded,
          title: 'Daily Login',
          description: 'Log in every day to receive bonus Gold.',
          reward: '+25 Gold',
          color: AppTheme.neonPurple,
        ),
        const SizedBox(height: 12),
        _EarnTile(
          icon: Icons.local_fire_department_rounded,
          title: 'Win Streak (5x)',
          description: 'Win 5 games in a row for a huge reward.',
          reward: '+250 Gold',
          color: Colors.orange,
        ),
      ],
    );
  }
}

class _SkinItem {
  final String name;
  final String icon;
  final int price;
  bool owned;
  final Color color;
  _SkinItem({required this.name, required this.icon, required this.price, required this.owned, required this.color});
}

class _SkinGrid extends StatelessWidget {
  final List<_SkinItem> skins;
  final int gold;
  final Function(_SkinItem) onBuy;
  const _SkinGrid({required this.skins, required this.gold, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: skins.length,
      itemBuilder: (_, i) {
        final item = skins[i];
        final canAfford = gold >= item.price;
        return GestureDetector(
          onTap: () { if (!item.owned && canAfford) onBuy(item); },
          child: Container(
            decoration: BoxDecoration(
              color: item.owned ? item.color.withOpacity(0.08) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.owned ? item.color : AppTheme.textMuted.withOpacity(0.3),
                width: item.owned ? 1.5 : 1,
              ),
              boxShadow: item.owned ? [BoxShadow(color: item.color.withOpacity(0.2), blurRadius: 12)] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.icon, style: TextStyle(fontSize: 48,
                    shadows: [Shadow(color: item.color, blurRadius: 16)])),
                const SizedBox(height: 10),
                Text(item.name, style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary, fontSize: 13)),
                const SizedBox(height: 6),
                if (item.owned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('OWNED', style: AppTheme.labelSmall.copyWith(color: item.color, fontSize: 9)),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('⬡', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('${item.price}',
                          style: AppTheme.titleMedium.copyWith(
                              color: canAfford ? AppTheme.gold : AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EarnTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String reward;
  final Color color;
  const _EarnTile({required this.icon, required this.title, required this.description, required this.reward, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
              color: AppTheme.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
            ),
            child: Text(reward, style: AppTheme.labelSmall.copyWith(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }
}
