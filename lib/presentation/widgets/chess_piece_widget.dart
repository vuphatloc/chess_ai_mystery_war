import 'package:flutter/material.dart';
import '../../domain/entities/piece.dart';
import '../../domain/value_objects/piece_color.dart';
import '../../domain/value_objects/piece_type.dart';
import '../../domain/models/skin_registry.dart';

/// Renders a chess piece with clear white/black visual differentiation.
///
/// Design principles:
///  - White pieces: warm cream fill (#FEFCF5→#D8CEB4), dark symbol
///  - Black pieces: near-black fill (#2A2A32→#0C0C10), light symbol
///  - Accent ring border taken from the skin — no ambiguity about color
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
    final borderColor = isWhite ? skin.whiteBorder : skin.blackBorder;
    final glowColor = isWhite ? skin.whiteGlow : skin.blackGlow;

    // Always use filled solid symbol — differentiated by fill+symbol color pair
    final symbol = _getSymbol(piece.currentType);

    // Clear cream (white pieces) vs near-black (black pieces)
    final fillGradient = isWhite
        ? const RadialGradient(
            center: Alignment(-0.3, -0.45),
            radius: 0.9,
            colors: [Color(0xFFFEFCF5), Color(0xFFCFC5A8)],
          )
        : const RadialGradient(
            center: Alignment(-0.3, -0.45),
            radius: 0.9,
            colors: [Color(0xFF2E2E3A), Color(0xFF0C0C10)],
          );

    // Symbol: Use harmonious trim colors instead of stark black/white
    // White piece -> Warm golden/brown trim, Black piece -> Cool silver/grey trim
    final symbolColor =
        isWhite ? const Color(0xFF8C7558) : const Color(0xFF9595A5);

    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 2.5D ground shadow (only for 2.5D skins)
          if (skin.is25D)
            Positioned(
              bottom: size * 0.01,
              child: Container(
                width: size * 0.68,
                height: size * 0.13,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.1),
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

          // Selection glow halo
          if (isSelected)
            Container(
              width: size * 0.90,
              height: size * 0.90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.9),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),

          // Accent ring — skin border color creates clear visual identity
          // and acts as separator from the board square beneath
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: borderColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 5,
                  offset: const Offset(1, 3),
                ),
              ],
            ),
          ),

          // Main piece body (slightly smaller — shows accent ring as border)
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: fillGradient,
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  // White pieces need slightly larger font to match the visual weight
                  // of black pieces (dark ink on cream recedes vs light on dark).
                  // Pawn glyph (♟) is inherently wider — scale it down to match others.
                  fontSize: _symbolFontSize(piece.currentType, isWhite, size),
                  color: symbolColor,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 2,
                      offset: const Offset(0.5, 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Per-type font size with corrections:
  ///  - White symbols: +0.03× to compensate dark-on-light visual shrinkage
  ///  - Pawn: −0.05× because ♟ renders much wider/taller than other glyphs
  double _symbolFontSize(PieceType type, bool isWhite, double size) {
    final base = isWhite ? size * 0.51 : size * 0.48;
    if (type == PieceType.pawn) return base - size * 0.05;
    return base;
  }

  /// All pieces use filled (solid silhouette) symbols for the embossed look.
  String _getSymbol(PieceType type) {
    switch (type) {
      case PieceType.pawn:   return '♙';
      case PieceType.rook:   return '♖';
      case PieceType.knight: return '♘';
      case PieceType.bishop: return '♗';
      case PieceType.queen:  return '♕';
      case PieceType.king:   return '♔';
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
        // White piece (king)
        Container(
          width: size * 0.84,
          height: size * 0.84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: skin.whiteBorder,
            boxShadow: [BoxShadow(color: skin.whiteGlow.withValues(alpha: 0.5), blurRadius: 10)],
          ),
          child: Center(
            child: Container(
              width: size * 0.74,
              height: size * 0.74,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFFFEFCF5), Color(0xFFCFC5A8)],
                ),
              ),
              child: Center(
                child: Text(
                  '♔',
                  style: TextStyle(
                    fontSize: size * 0.51,
                    color: const Color(0xFF8C7558),
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 2,
                        offset: const Offset(0.5, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Black piece overlay (rook) — bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.46,
            height: size * 0.46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: skin.blackBorder,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
            ),
            child: Center(
              child: Container(
                width: size * 0.38,
                height: size * 0.38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF2E2E3A), Color(0xFF0C0C10)],
                  ),
                ),
                child: Center(
                  child: Text(
                    '♖',
                    style: TextStyle(
                      fontSize: size * 0.24,
                      color: const Color(0xFF9595A5),
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 2,
                          offset: const Offset(0.5, 1.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


