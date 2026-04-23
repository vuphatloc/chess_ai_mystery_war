import 'package:flutter/material.dart';
import '../../domain/entities/piece.dart';
import '../../domain/value_objects/piece_color.dart';
import '../../domain/value_objects/piece_type.dart';
import '../../domain/models/skin_registry.dart';

/// Renders a chess piece with the given skin — 2D/2.5D style.
class ChessPieceWidget extends StatelessWidget {
  final Piece piece;
  final PieceSkinDef skin;
  final double size;
  final bool isSelected;
  final bool isValidTarget;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    required this.skin,
    required this.size,
    this.isSelected = false,
    this.isValidTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PieceColor.white;
    final faceColor = isWhite ? skin.whiteColor : skin.blackColor;
    final borderColor = isWhite ? skin.whiteBorder : skin.blackBorder;
    final glowColor = isWhite ? skin.whiteGlow : skin.blackGlow;
    final symbol = _getSymbol(piece.currentType, isWhite);

    return AnimatedScale(
      scale: isSelected ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 2.5D shadow layer
          if (skin.is25D)
            Positioned(
              bottom: size * 0.02,
              child: Container(
                width: size * 0.75,
                height: size * 0.18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.08),
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

          // Piece background circle
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.8,
                colors: isWhite
                    ? [faceColor, faceColor.withValues(alpha: 0.85)]
                    : [
                        Color.lerp(faceColor, Colors.white, 0.12)!,
                        faceColor,
                      ],
              ),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.5 : (isWhite ? 1.5 : 2.0),
              ),
              boxShadow: [
                // Glow effect
                BoxShadow(
                  color: glowColor.withValues(alpha: isSelected ? 0.8 : 0.4),
                  blurRadius: isSelected ? 16 : 8,
                  spreadRadius: isSelected ? 2 : 0,
                ),
                // Base shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(1, 2),
                ),
                // Inner highlight for white pieces
                if (isWhite)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(-1, -1),
                  ),
              ],
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: size * 0.56,
                  color: isWhite
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFE8E8FF),
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: isWhite
                          ? borderColor.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selection ring
          if (isSelected)
            Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getSymbol(PieceType type, bool isWhite) {
    // Use filled symbols that look consistent in all skins
    switch (type) {
      case PieceType.pawn:   return isWhite ? '♙' : '♟';
      case PieceType.rook:   return isWhite ? '♖' : '♜';
      case PieceType.knight: return isWhite ? '♘' : '♞';
      case PieceType.bishop: return isWhite ? '♗' : '♝';
      case PieceType.queen:  return isWhite ? '♕' : '♛';
      case PieceType.king:   return isWhite ? '♔' : '♚';
    }
  }
}

/// Preview widget for piece skins in Store/Inventory
class PieceSkinPreview extends StatelessWidget {
  final PieceSkinDef skin;
  final double size;

  const PieceSkinPreview({super.key, required this.skin, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Show white piece (knight) as preview
        Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              radius: 0.8,
              colors: [skin.whiteColor, skin.whiteColor.withValues(alpha: 0.85)],
            ),
            border: Border.all(color: skin.whiteBorder, width: 2),
            boxShadow: [
              BoxShadow(color: skin.whiteGlow.withValues(alpha: 0.5), blurRadius: 14),
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(1, 2)),
            ],
          ),
          child: Center(
            child: Text(
              '♘',
              style: TextStyle(
                fontSize: size * 0.56,
                color: const Color(0xFF1A1A2E),
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: skin.whiteBorder.withValues(alpha: 0.5), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
        // Show black piece overlay (rook)
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.8,
                colors: [
                  Color.lerp(skin.blackColor, Colors.white, 0.15)!,
                  skin.blackColor,
                ],
              ),
              border: Border.all(color: skin.blackBorder, width: 1.5),
              boxShadow: [
                BoxShadow(color: skin.blackGlow.withValues(alpha: 0.5), blurRadius: 8),
              ],
            ),
            child: Center(
              child: Text(
                '♜',
                style: TextStyle(
                  fontSize: size * 0.26,
                  color: const Color(0xFFE8E8FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
