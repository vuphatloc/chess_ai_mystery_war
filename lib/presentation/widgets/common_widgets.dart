import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A premium neon button with glow effect and press animation
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color color;
  final bool isWide;
  final double height;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = AppTheme.neonCyan,
    this.isWide = false,
    this.height = 56,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _anim.forward(),
      onTapUp: (_) {
        _anim.reverse();
        widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: widget.height,
          width: widget.isWide ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color.withOpacity(0.15), widget.color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color, width: 1.5),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisSize: widget.isWide ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: AppTheme.titleMedium.copyWith(
                  color: widget.color,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glass card container
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        borderRadius: borderRadius,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}

/// Gold currency badge
class GoldBadge extends StatelessWidget {
  final int amount;
  const GoldBadge({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F00), Color(0xFF1A1200)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: AppTheme.goldGlow, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⬡', style: TextStyle(color: AppTheme.gold, fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$amount',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
