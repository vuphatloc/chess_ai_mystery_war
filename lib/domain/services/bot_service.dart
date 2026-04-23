import 'dart:math';
import 'package:flutter/foundation.dart';

import '../entities/board.dart';
import '../entities/piece.dart';
import '../entities/game_rules_engine.dart';
import '../value_objects/position.dart';
import '../value_objects/piece_color.dart';
import '../value_objects/piece_type.dart';
import '../models/game_config.dart';

/// A bot move candidate.
class BotMove {
  final Piece piece;
  final Position target;
  const BotMove(this.piece, this.target);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Bot AI parameters — sourced directly from bot_mode.md spec:
///
/// Elo Range     | Rank        | Max Depth | Error Rate | Think Time (ms)
/// 400 - 600     | Beginner    |   1-2     |    40%     |   800 - 1500
/// 600 - 900     | Novice      |    2      |    25%     |  1000 - 2000
/// 900 - 1200    | Intermediate|    3      |    15%     |  1500 - 3000
/// 1200 - 1500   | Advanced    |    4      |     8%     |  2000 - 4000
/// 1500 - 1800   | Expert      |   5-6     |     3%     |  3000 - 6000
/// 1800 - 2100   | Master      |    8      |     1%     |  4000 - 8000
/// 2100 - 2500   | Grandmaster |   12      |     0%     |  5000 - 8000
/// ─────────────────────────────────────────────────────────────────────────────
class _BotParams {
  final int maxDepth;
  final double errorRate;  // probability of random (human-error) move
  final int thinkMinMs;
  final int thinkMaxMs;

  const _BotParams({
    required this.maxDepth,
    required this.errorRate,
    required this.thinkMinMs,
    required this.thinkMaxMs,
  });
}

const _params = {
  BotDifficulty.beginner:     _BotParams(maxDepth: 1,  errorRate: 0.40, thinkMinMs: 800,  thinkMaxMs: 1500),
  BotDifficulty.novice:       _BotParams(maxDepth: 1,  errorRate: 0.25, thinkMinMs: 1000, thinkMaxMs: 2000),
  BotDifficulty.intermediate: _BotParams(maxDepth: 2,  errorRate: 0.15, thinkMinMs: 1500, thinkMaxMs: 3000),
  BotDifficulty.advanced:     _BotParams(maxDepth: 2,  errorRate: 0.08, thinkMinMs: 2000, thinkMaxMs: 4000),
  BotDifficulty.expert:       _BotParams(maxDepth: 2,  errorRate: 0.03, thinkMinMs: 3000, thinkMaxMs: 6000),
  BotDifficulty.master:       _BotParams(maxDepth: 3,  errorRate: 0.01, thinkMinMs: 4000, thinkMaxMs: 8000),
  BotDifficulty.grandmaster:  _BotParams(maxDepth: 3,  errorRate: 0.00, thinkMinMs: 5000, thinkMaxMs: 8000),
};


class BotService {
  final BotDifficulty difficulty;
  final MysterySubType? mysterySubType;
  final Random _random;

  BotService({
    required this.difficulty,
    this.mysterySubType,
    Random? random,
  }) : _random = random ?? Random();

  _BotParams get _p => _params[difficulty]!;

  /// Returns the best move for [color].
  /// Includes simulated think time per bot_mode.md UX spec.
  Future<BotMove?> getBestMove(Board board, PieceColor color) async {
    // Simulated think time (UX realism)
    final thinkMs = _thinkTimeMs();
    await Future.delayed(Duration(milliseconds: thinkMs));

    return _selectMove(board, color);
  }

  int _thinkTimeMs() {
    return _p.thinkMinMs +
        _random.nextInt((_p.thinkMaxMs - _p.thinkMinMs).clamp(1, 9999));
  }

  Future<BotMove?> _selectMove(Board board, PieceColor color) async {
    final allMoves = _gatherMoves(board, color);
    if (allMoves.isEmpty) return null;

    // applyHumanError(): if random < errorRate, return random legal move
    if (_random.nextDouble() < _p.errorRate) {
      return allMoves[_random.nextInt(allMoves.length)];
    }

    // Special logic for mystery modes
    if (mysterySubType != null && _p.errorRate > 0.05) {
      // Low-Elo mystery: treat hidden pieces as unknown, pick moves randomly
      // among revealed pieces first, then hidden
      return _mysteryAwareLowElo(board, color, allMoves);
    }

    // Strip heavy object graphs (moveHistory, captures) to prevent massive serialization lag
    // across the Isolate boundary!
    final lightweightBoard = board.copyWith(
      moveHistory: const [],
      capturedWhitePieces: const [],
      capturedBlackPieces: const [],
    );

    // Run Minimax in background Isolate to prevent UI freeze
    return await compute(_runMinimaxRoot, _ComputeArgs(lightweightBoard, color, _p.maxDepth, allMoves));
  }

  static List<BotMove> _gatherMoves(Board board, PieceColor color) {
    final moves = <BotMove>[];
    for (final piece in board.getPiecesByColor(color)) {
      for (final target in GameRulesEngine.getValidMoves(board, piece)) {
        moves.add(BotMove(piece, target));
      }
    }
    return moves;
  }

  BotMove _mysteryAwareLowElo(Board board, PieceColor color, List<BotMove> moves) {
    // Beginner/Novice: bot treats hidden pieces as 'unknown', mostly random
    final revealedMoves = moves.where((m) => m.piece.isRevealed).toList();
    final pool = revealedMoves.isNotEmpty ? revealedMoves : moves;
    return pool[_random.nextInt(pool.length)];
  }
}

class _ComputeArgs {
  final Board board;
  final PieceColor color;
  final int maxDepth;
  final List<BotMove> allMoves;
  _ComputeArgs(this.board, this.color, this.maxDepth, this.allMoves);
}

BotMove? _runMinimaxRoot(_ComputeArgs args) {
  BotMove? best;
  int bestScore = args.color == PieceColor.black ? -999999 : 999999;

  for (final move in args.allMoves) {
    final next = args.board.movePiece(move.piece, move.target);
    final score = _minimax(next, args.maxDepth - 1, -999999, 999999,
        args.color == PieceColor.white);

    if (args.color == PieceColor.black && score > bestScore) {
      bestScore = score;
      best = move;
    } else if (args.color == PieceColor.white && score < bestScore) {
      bestScore = score;
      best = move;
    }
  }
  return best ?? args.allMoves.first;
}

int _minimax(Board board, int depth, int alpha, int beta, bool maximizing) {
  if (depth == 0) return _evaluate(board);

  final color = maximizing ? PieceColor.black : PieceColor.white;
  final pieces = board.getPiecesByColor(color);
  bool hasMoves = false;

  if (maximizing) {
    int maxEval = -999999;
    for (final piece in pieces) {
      for (final target in GameRulesEngine.getValidMoves(board, piece)) {
        hasMoves = true;
        final nb = board.movePiece(piece, target);
        final eval = _minimax(nb, depth - 1, alpha, beta, false);
        if (eval > maxEval) maxEval = eval;
        if (maxEval > alpha) alpha = maxEval;
        if (beta <= alpha) return maxEval;
      }
    }
    return hasMoves ? maxEval : _evaluate(board);
  } else {
    int minEval = 999999;
    for (final piece in pieces) {
      for (final target in GameRulesEngine.getValidMoves(board, piece)) {
        hasMoves = true;
        final nb = board.movePiece(piece, target);
        final eval = _minimax(nb, depth - 1, alpha, beta, true);
        if (eval < minEval) minEval = eval;
        if (minEval < beta) beta = minEval;
        if (beta <= alpha) return minEval;
      }
    }
    return hasMoves ? minEval : _evaluate(board);
  }
}

int _evaluate(Board board) {

    int score = 0;
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = board.squares[rank][file];
        if (piece == null) continue;
        final v = _pieceValue(piece.actualType) +
            _posBonus(piece.actualType, file, rank, piece.color);
        score += piece.color == PieceColor.black ? v : -v;
      }
    }
    return score;
  }

  int _pieceValue(PieceType t) {
    switch (t) {
      case PieceType.pawn:   return 100;
      case PieceType.knight: return 320;
      case PieceType.bishop: return 330;
      case PieceType.rook:   return 500;
      case PieceType.queen:  return 900;
      case PieceType.king:   return 20000;
    }
  }

  int _posBonus(PieceType type, int file, int rank, PieceColor color) {
    final r = color == PieceColor.white ? rank : 7 - rank;
    switch (type) {
      case PieceType.pawn:   return _pawn[r][file];
      case PieceType.knight: return _knight[r][file];
      case PieceType.bishop: return _bishop[r][file];
      case PieceType.rook:   return _rook[r][file];
      case PieceType.queen:  return _queen[r][file];
      case PieceType.king:   return _king[r][file];
    }
  }

  // ── Piece-Square Tables (centipawns) ─────────────────────────────────────
  const _pawn = [
    [ 0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [ 5,  5, 10, 25, 25, 10,  5,  5],
    [ 0,  0,  0, 20, 20,  0,  0,  0],
    [ 5, -5,-10,  0,  0,-10, -5,  5],
    [ 5, 10, 10,-20,-20, 10, 10,  5],
    [ 0,  0,  0,  0,  0,  0,  0,  0],
  ];
  const _knight = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50],
  ];
  const _bishop = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
  ];
  const _rook = [
    [ 0,  0,  0,  0,  0,  0,  0,  0],
    [ 5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [ 0,  0,  0,  5,  5,  0,  0,  0],
  ];
  const _queen = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [ -5,  0,  5,  5,  5,  5,  0, -5],
    [  0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20],
  ];
  const _king = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [ 20, 20,  0,  0,  0,  0, 20, 20],
    [ 20, 30, 10,  0,  0, 10, 30, 20],
  ];
