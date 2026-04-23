import 'package:flutter/material.dart';

/// A theme configuration for the app's color scheme.
class ThemeColors {
  final String name;
  final Color primary;
  final Color secondary;
  final Color boardLight;
  final Color boardDark;
  final Color boardBorder;
  final LinearGradient boardGradient;

  const ThemeColors({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.boardLight,
    required this.boardDark,
    required this.boardBorder,
    required this.boardGradient,
  });
}

/// Defines visual appearance of a piece skin.
class PieceSkinDef {
  final String id;
  final String name;
  final String previewIcon;
  final int price;
  final Color whiteColor;
  final Color whiteBorder;
  final Color whiteGlow;
  final Color blackColor;
  final Color blackBorder;
  final Color blackGlow;
  final bool is25D; // 2.5D perspective style

  const PieceSkinDef({
    required this.id,
    required this.name,
    required this.previewIcon,
    required this.price,
    required this.whiteColor,
    required this.whiteBorder,
    required this.whiteGlow,
    required this.blackColor,
    required this.blackBorder,
    required this.blackGlow,
    this.is25D = false,
  });
}

/// Defines visual appearance of a board skin.
class BoardSkinDef {
  final String id;
  final String name;
  final String previewEmoji;
  final int price;
  final Color lightSquare;
  final Color darkSquare;
  final Color? highlightTint;
  final List<BoxShadow>? boardGlow;

  const BoardSkinDef({
    required this.id,
    required this.name,
    required this.previewEmoji,
    required this.price,
    required this.lightSquare,
    required this.darkSquare,
    this.highlightTint,
    this.boardGlow,
  });
}

/// Central registry for all available skins.
class SkinRegistry {
  // ── App Themes ───────────────────────────────────────────────────────────
  static const List<ThemeColors> themes = [
    ThemeColors(
      name: 'Cyber Neon',
      primary: Color(0xFF00E5FF),
      secondary: Color(0xFFAA00FF),
      boardLight: Color(0xFF2A3A4A),
      boardDark: Color(0xFF1A2535),
      boardBorder: Color(0xFF00E5FF),
      boardGradient: LinearGradient(colors: [Color(0xFF003D40), Color(0xFF001A1C)]),
    ),
    ThemeColors(
      name: 'Golden Knight',
      primary: Color(0xFFFFD700),
      secondary: Color(0xFFFF8C00),
      boardLight: Color(0xFF3A3020),
      boardDark: Color(0xFF1E1A10),
      boardBorder: Color(0xFFFFD700),
      boardGradient: LinearGradient(colors: [Color(0xFF3D3000), Color(0xFF1C1500)]),
    ),
    ThemeColors(
      name: 'Blood Moon',
      primary: Color(0xFFFF1744),
      secondary: Color(0xFFFF6D00),
      boardLight: Color(0xFF3A2020),
      boardDark: Color(0xFF1E1010),
      boardBorder: Color(0xFFFF1744),
      boardGradient: LinearGradient(colors: [Color(0xFF3D0000), Color(0xFF1C0000)]),
    ),
    ThemeColors(
      name: 'Arctic Ice',
      primary: Color(0xFF80D8FF),
      secondary: Color(0xFF00E5FF),
      boardLight: Color(0xFF2A3A4A),
      boardDark: Color(0xFF162030),
      boardBorder: Color(0xFF80D8FF),
      boardGradient: LinearGradient(colors: [Color(0xFF003050), Color(0xFF001525)]),
    ),
  ];

  // ── Piece Skins ───────────────────────────────────────────────────────────
  static const List<PieceSkinDef> pieceSkins = [
    PieceSkinDef(
      id: 'cyber_neon',
      name: 'Cyber Neon',
      previewIcon: '♞',
      price: 0,
      whiteColor: Color(0xFFF0F8FF),
      whiteBorder: Color(0xFF00E5FF),
      whiteGlow: Color(0xFF00E5FF),
      blackColor: Color(0xFF1A2535),
      blackBorder: Color(0xFF00E5FF),
      blackGlow: Color(0xFF0080A0),
    ),
    PieceSkinDef(
      id: 'classic_wood',
      name: 'Classic Wood',
      previewIcon: '♞',
      price: 300,
      whiteColor: Color(0xFFF5DEB3),
      whiteBorder: Color(0xFF8B6914),
      whiteGlow: Color(0xFFDAA520),
      blackColor: Color(0xFF3D2B1F),
      blackBorder: Color(0xFF8B6914),
      blackGlow: Color(0xFF5C3D2A),
    ),
    PieceSkinDef(
      id: 'holographic',
      name: 'Holographic',
      previewIcon: '♞',
      price: 800,
      whiteColor: Color(0xFFE8F4FD),
      whiteBorder: Color(0xFFAA00FF),
      whiteGlow: Color(0xFFAA00FF),
      blackColor: Color(0xFF1A0A2E),
      blackBorder: Color(0xFFAA00FF),
      blackGlow: Color(0xFF6A0080),
      is25D: true,
    ),
    PieceSkinDef(
      id: 'fire_elemental',
      name: 'Fire Elemental',
      previewIcon: '♞',
      price: 1200,
      whiteColor: Color(0xFFFFF3E0),
      whiteBorder: Color(0xFFFF6D00),
      whiteGlow: Color(0xFFFF9800),
      blackColor: Color(0xFF1A0A00),
      blackBorder: Color(0xFFFF6D00),
      blackGlow: Color(0xFFBF360C),
    ),
    PieceSkinDef(
      id: 'ice_crystal',
      name: 'Ice Crystal',
      previewIcon: '♞',
      price: 1000,
      whiteColor: Color(0xFFE1F5FE),
      whiteBorder: Color(0xFF40C4FF),
      whiteGlow: Color(0xFF00B0FF),
      blackColor: Color(0xFF0A1929),
      blackBorder: Color(0xFF40C4FF),
      blackGlow: Color(0xFF006064),
      is25D: true,
    ),
    PieceSkinDef(
      id: 'dark_matter',
      name: 'Dark Matter',
      previewIcon: '♞',
      price: 1500,
      whiteColor: Color(0xFFEDE7F6),
      whiteBorder: Color(0xFF7C4DFF),
      whiteGlow: Color(0xFFAA00FF),
      blackColor: Color(0xFF120020),
      blackBorder: Color(0xFF7C4DFF),
      blackGlow: Color(0xFF4A148C),
      is25D: true,
    ),
  ];

  // ── Board Skins ────────────────────────────────────────────────────────────
  static const List<BoardSkinDef> boardSkins = [
    BoardSkinDef(
      id: 'deep_space',
      name: 'Deep Space',
      previewEmoji: '🌌',
      price: 0,
      lightSquare: Color(0xFF2A3A4A),
      darkSquare: Color(0xFF162030),
      highlightTint: Color(0xFF00E5FF),
    ),
    BoardSkinDef(
      id: 'marble_palace',
      name: 'Marble Palace',
      previewEmoji: '🏛',
      price: 600,
      lightSquare: Color(0xFFE8E0D8),
      darkSquare: Color(0xFF8B7355),
      highlightTint: Color(0xFFFFD700),
    ),
    BoardSkinDef(
      id: 'cyberpunk_city',
      name: 'Cyberpunk City',
      previewEmoji: '🌆',
      price: 1000,
      lightSquare: Color(0xFF2A1A35),
      darkSquare: Color(0xFF150D20),
      highlightTint: Color(0xFFAA00FF),
    ),
    BoardSkinDef(
      id: 'enchanted_forest',
      name: 'Enchanted Forest',
      previewEmoji: '🌲',
      price: 700,
      lightSquare: Color(0xFF2D4A2D),
      darkSquare: Color(0xFF152515),
      highlightTint: Color(0xFF69F0AE),
    ),
  ];

  static PieceSkinDef getSkin(String id) =>
      pieceSkins.firstWhere((s) => s.id == id, orElse: () => pieceSkins.first);

  static BoardSkinDef getBoardSkin(String id) =>
      boardSkins.firstWhere((s) => s.id == id, orElse: () => boardSkins.first);

  static ThemeColors getTheme(int index) =>
      themes[index.clamp(0, themes.length - 1)];
}
