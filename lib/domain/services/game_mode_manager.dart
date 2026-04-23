import '../entities/board.dart';
import '../entities/piece.dart';
import '../value_objects/position.dart';
import '../value_objects/piece_color.dart';
import '../models/game_config.dart';
import '../entities/game_rules_engine.dart';

/// Visibility map: 8x8 boolean grid — which squares are visible to current player
typedef VisibilityMap = List<List<bool>>;

/// Base class — Strategy Pattern.
/// Each mystery sub-type overrides getAvailableMoves() and getVisibleSquares().
abstract class GameModeManager {
  /// Factory: instantiate the correct manager from GameConfig.
  static GameModeManager fromConfig(GameConfig config) {
    if (config.mode == GameMode.normal || config.mode == GameMode.champion) {
      return NormalModeManager();
    }
    switch (config.mysterySubType) {
      case MysterySubType.hiddenIdentity:
        return HiddenIdentityManager();
      case MysterySubType.fogOfWar:
        return FogOfWarManager();
      case MysterySubType.blindfold:
        return BlindfoldManager();
      case MysterySubType.doubleBlind:
        return DoubleBlindManager();
      case null:
        return NormalModeManager();
    }
  }

  /// Returns available moves for this piece in the current mode.
  List<Position> getAvailableMoves(Board board, Piece piece) {
    return GameRulesEngine.getValidMoves(board, piece);
  }

  /// Returns a VisibilityMap for [color] — which squares they can see.
  VisibilityMap getVisibleSquares(Board board, PieceColor color) {
    return _fullVisibility();
  }

  /// Whether a specific piece is rendered visible to [viewerColor].
  bool isPieceVisible(Board board, Piece piece, PieceColor viewerColor,
      VisibilityMap visMap) {
    return visMap[piece.position.rank][piece.position.file];
  }

  /// Whether a piece should render as "face-down" (unknown type).
  bool isPieceFaceDown(Piece piece, PieceColor viewerColor, int totalMoves) {
    return false;
  }

  /// Whether the current move count triggers blindfold hide.
  bool get isBlindfoldActive => false;

  /// Full 8x8 all-visible map.
  static VisibilityMap _fullVisibility() =>
      List.generate(8, (_) => List.filled(8, true));
}

// ────────────────────────────────────────────────────────────────────────────
// 1. Normal Mode
// ────────────────────────────────────────────────────────────────────────────
class NormalModeManager extends GameModeManager {
  // All pieces revealed from start in normal mode
  @override
  bool isPieceFaceDown(Piece piece, PieceColor viewerColor, int totalMoves) =>
      false;
}

// ────────────────────────────────────────────────────────────────────────────
// 2. Hidden Identity (Cờ Úp)
//    - visualRole: position-based apparent type (before reveal)
//    - actualRole: real type
//    - isRevealed == false → moves per apparentType
//    - isRevealed == true  → moves per actualType
//    - King always revealed (per spec)
//    - Reveal trigger: immediately after move
// ────────────────────────────────────────────────────────────────────────────
class HiddenIdentityManager extends GameModeManager {
  @override
  List<Position> getAvailableMoves(Board board, Piece piece) {
    // Move rules depend on isRevealed (uses piece.currentType which already handles this)
    return GameRulesEngine.getValidMoves(board, piece);
  }

  @override
  bool isPieceFaceDown(Piece piece, PieceColor viewerColor, int totalMoves) {
    // Own pieces that are not yet revealed show as face-down
    // Opponent pieces always face-down until revealed
    return !piece.isRevealed;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 3. Fog of War (Cờ Sương Mù)
//    - VisibilityMap: computed each turn from current player's piece moves
//    - Opponent pieces outside visibility are hidden
//    - All pieces are always revealed (isRevealed = true default)
// ────────────────────────────────────────────────────────────────────────────
class FogOfWarManager extends GameModeManager {
  @override
  VisibilityMap getVisibleSquares(Board board, PieceColor color) {
    final map = List.generate(8, (_) => List.filled(8, false));

    final myPieces = board.getPiecesByColor(color);
    for (final piece in myPieces) {
      // Own piece position is always visible
      map[piece.position.rank][piece.position.file] = true;

      // All squares this piece can move to (or attack) are visible
      final moves = GameRulesEngine.getValidMoves(board, piece);
      for (final pos in moves) {
        map[pos.rank][pos.file] = true;
      }
    }
    return map;
  }

  @override
  bool isPieceFaceDown(Piece piece, PieceColor viewerColor, int totalMoves) =>
      false; // identity always known in fog-of-war

  @override
  bool isPieceVisible(Board board, Piece piece, PieceColor viewerColor,
      VisibilityMap visMap) {
    // Own pieces always visible
    if (piece.color == viewerColor) return true;
    // Opponent: only visible if in view range
    return visMap[piece.position.rank][piece.position.file];
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 4. Blindfold Chess (Cờ Mù)
//    - Full visibility map (see all positions)
//    - After totalMoves > 12 (each side 6 moves): pieces rendered invisible
//    - Logic (collision, moves) unchanged — only UI rendering hidden
//    - "Peek" costs Gold and shows pieces for 2 seconds
// ────────────────────────────────────────────────────────────────────────────
class BlindfoldManager extends GameModeManager {
  @override
  bool get isBlindfoldActive => true;

  @override
  bool isPieceFaceDown(Piece piece, PieceColor viewerColor, int totalMoves) {
    // After hideAfterMoves total plies, render all pieces as invisible
    return totalMoves >= 12;
  }

  // Full visibility (you can still click any square)
  @override
  VisibilityMap getVisibleSquares(Board board, PieceColor color) =>
      List.generate(8, (_) => List.filled(8, true));
}

// ────────────────────────────────────────────────────────────────────────────
// 5. Double Blind (Tối Thượng)
//    Combines Hidden Identity + Fog of War:
//    - You don't know your piece identity until it moves (isRevealed)
//    - You can't see enemy pieces outside your control range
// ────────────────────────────────────────────────────────────────────────────
class DoubleBlindManager extends GameModeManager {
  final _fog = FogOfWarManager();
  final _hidden = HiddenIdentityManager();

  @override
  List<Position> getAvailableMoves(Board board, Piece piece) =>
      _hidden.getAvailableMoves(board, piece);

  @override
  VisibilityMap getVisibleSquares(Board board, PieceColor color) =>
      _fog.getVisibleSquares(board, color);

  @override
  bool isPieceVisible(Board board, Piece piece, PieceColor viewerColor,
      VisibilityMap visMap) =>
      _fog.isPieceVisible(board, piece, viewerColor, visMap);

  @override
  bool isPieceFaceDown(Piece piece, PieceColor viewerColor, int totalMoves) {
    // Own unrevealed pieces: face-down
    // Enemy pieces: face-down AND may be invisible (handled by isPieceVisible)
    return !piece.isRevealed;
  }
}
