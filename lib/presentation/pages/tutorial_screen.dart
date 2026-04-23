import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../presentation/widgets/common_widgets.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<_TutorialStep> _steps = [
    _TutorialStep(
      title: 'The Board',
      emoji: '♟',
      color: AppTheme.neonCyan,
      content: '''Chess is played on an 8×8 board with 64 squares, alternating in light and dark colors.

Each player starts with 16 pieces arranged on their side. You play as White and go first.

The board columns are called **Files** (a–h), and rows are called **Ranks** (1–8).''',
    ),
    _TutorialStep(
      title: 'The Pieces',
      emoji: '♔',
      color: AppTheme.neonPurple,
      content: '''Each piece moves differently:

♔ **King** — One square in any direction. Protect at all costs!
♕ **Queen** — Any number of squares in any direction. Most powerful!
♖ **Rook** — Any number of squares horizontally or vertically.
♗ **Bishop** — Any number of squares diagonally.
♘ **Knight** — "L" shape: 2 squares + 1 turn. Jumps over pieces!
♙ **Pawn** — Forward 1 square (or 2 from start). Captures diagonally.''',
    ),
    _TutorialStep(
      title: 'Check & Checkmate',
      emoji: '⚠',
      color: Colors.red,
      content: '''**Check** — Your King is under attack! You MUST escape.

**Checkmate** — Your King is in Check with no escape. Game over!

**Stalemate** — You have no legal moves but are NOT in check. Draw!

Always watch out for your King's safety. The game ends the moment checkmate occurs.''',
    ),
    _TutorialStep(
      title: 'Opening Strategy',
      emoji: '🧠',
      color: AppTheme.gold,
      content: '''Start strong with these principles:

1. **Control the center** — Occupy e4, d4, e5, d5 squares.
2. **Develop pieces** — Move Knights and Bishops first, not the same piece twice.
3. **Castle early** — Protect your King by castling (King + Rook swap).
4. **Don't rush your Queen** — She's powerful but easy to trap early.''',
    ),
    _TutorialStep(
      title: 'Mystery Mode',
      emoji: '🌫',
      color: AppTheme.neonPurple,
      content: '''Mystery Mode adds exciting twists!

🌫 **Fog of War** — You can only see squares your pieces can reach.

🎲 **Random Events** — Tiles may buff your pieces or trap enemies. Always expect the unexpected!

✨ **Mystery Pieces** — Some pieces hide their true type until they move. Bluff your opponent!

The core chess rules still apply. Master Normal mode first, then dive into Mystery!''',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentStep = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _buildStep(_steps[i]),
              ),
            ),
            _buildNavButtons(),
          ],
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
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TUTORIAL', style: AppTheme.labelSmall),
              Text('Chess for Beginners', style: AppTheme.titleLarge),
            ],
          ),
          const Spacer(),
          Text(
            '${_currentStep + 1} / ${_steps.length}',
            style: AppTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_steps.length, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? _steps[_currentStep].color
                    : AppTheme.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
                boxShadow: i == _currentStep
                    ? [BoxShadow(color: _steps[_currentStep].color.withOpacity(0.5), blurRadius: 6)]
                    : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(_TutorialStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [step.color.withOpacity(0.3), Colors.transparent],
                ),
                boxShadow: [BoxShadow(color: step.color.withOpacity(0.4), blurRadius: 30)],
              ),
              child: Center(
                child: Text(
                  step.emoji,
                  style: TextStyle(fontSize: 52,
                      shadows: [Shadow(color: step.color, blurRadius: 16)]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (b) => LinearGradient(
              colors: [step.color, step.color.withOpacity(0.7)],
            ).createShader(b),
            child: Text(step.title,
                style: AppTheme.displayMedium.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: step.color.withOpacity(0.2)),
            ),
            child: _buildRichText(step.content, step.color),
          ),
        ],
      ),
    );
  }

  Widget _buildRichText(String content, Color accent) {
    final lines = content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 8);

        // Bold detection: **text**
        if (line.contains('**')) {
          final parts = line.split('**');
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                style: AppTheme.bodyMedium.copyWith(height: 1.5),
                children: List.generate(parts.length, (i) {
                  return TextSpan(
                    text: parts[i],
                    style: i.isOdd
                        ? AppTheme.bodyMedium.copyWith(
                            color: accent, fontWeight: FontWeight.w700, height: 1.5)
                        : null,
                  );
                }),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line, style: AppTheme.bodyMedium.copyWith(height: 1.6)),
        );
      }).toList(),
    );
  }

  Widget _buildNavButtons() {
    final isLast = _currentStep == _steps.length - 1;
    final isFirst = _currentStep == 0;
    final color = _steps[_currentStep].color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.textMuted.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Previous', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
              ),
            ),
          if (!isFirst) const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: NeonButton(
              label: isLast ? 'FINISH' : 'NEXT',
              icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              color: color,
              isWide: true,
              onTap: () {
                if (isLast) {
                  Navigator.pop(context);
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final String title;
  final String emoji;
  final Color color;
  final String content;
  const _TutorialStep({required this.title, required this.emoji, required this.color, required this.content});
}
