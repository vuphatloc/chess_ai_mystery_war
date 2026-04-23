import '../value_objects/position.dart';
import '../value_objects/piece_type.dart';
import '../value_objects/piece_color.dart';
import '../value_objects/game_state.dart';
import 'board.dart';
import 'piece.dart';
import 'move.dart';

class GameRulesEngine {
  static List<Position> getValidMoves(Board board, Piece piece) {
    final validMoves = <Position>[];
    final currentType = piece.currentType;

    // Get moves based on current type (apparent or actual)
    final potentialMoves = _getPotentialMoves(board, piece, currentType);

    // Filter moves that don't put own king in check
    for (final move in potentialMoves) {
      if (_isMoveLegal(board, piece, move)) {
        validMoves.add(move);
      }
    }

    return validMoves;
  }

  static List<Position> _getPotentialMoves(
      Board board, Piece piece, PieceType type) {
    final moves = <Position>[];

    switch (type) {
      case PieceType.pawn:
        moves.addAll(_getPawnMoves(board, piece));
        break;
      case PieceType.rook:
        moves.addAll(_getRookMoves(board, piece));
        break;
      case PieceType.knight:
        moves.addAll(_getKnightMoves(board, piece));
        break;
      case PieceType.bishop:
        moves.addAll(_getBishopMoves(board, piece));
        break;
      case PieceType.queen:
        moves.addAll(_getQueenMoves(board, piece));
        break;
      case PieceType.king:
        moves.addAll(_getKingMoves(board, piece));
        break;
    }

    return moves;
  }

  static List<Position> _getPawnMoves(Board board, Piece pawn) {
    final moves = <Position>[];
    final position = pawn.position;
    final direction = pawn.color == PieceColor.white ? 1 : -1;
    final startRank = pawn.color == PieceColor.white ? 1 : 6;

    // Move forward one square
    final oneForward = Position(position.file, position.rank + direction);
    if (oneForward.isValid && board.getPieceAt(oneForward) == null) {
      moves.add(oneForward);

      // Move forward two squares from starting position
      if (position.rank == startRank) {
        final twoForward =
            Position(position.file, position.rank + 2 * direction);
        if (twoForward.isValid && board.getPieceAt(twoForward) == null) {
          moves.add(twoForward);
        }
      }
    }

    // Diagonal captures
    for (final fileOffset in [-1, 1]) {
      final capturePos =
          Position(position.file + fileOffset, position.rank + direction);
      if (capturePos.isValid) {
        final targetPiece = board.getPieceAt(capturePos);
        if (targetPiece != null && targetPiece.color != pawn.color) {
          moves.add(capturePos);
        }
      }
    }

    return moves;
  }

  static List<Position> _getRookMoves(Board board, Piece rook) {
    return _getLinearMoves(board, rook, [
      const Position(1, 0), // right
      const Position(-1, 0), // left
      const Position(0, 1), // up
      const Position(0, -1), // down
    ]);
  }

  static List<Position> _getKnightMoves(Board board, Piece knight) {
    final moves = <Position>[];
    final position = knight.position;

    final knightMoves = [
      const Position(2, 1),
      const Position(2, -1),
      const Position(-2, 1),
      const Position(-2, -1),
      const Position(1, 2),
      const Position(1, -2),
      const Position(-1, 2),
      const Position(-1, -2),
    ];

    for (final offset in knightMoves) {
      final newPos =
          Position(position.file + offset.file, position.rank + offset.rank);
      if (newPos.isValid) {
        final targetPiece = board.getPieceAt(newPos);
        if (targetPiece == null || targetPiece.color != knight.color) {
          moves.add(newPos);
        }
      }
    }

    return moves;
  }

  static List<Position> _getBishopMoves(Board board, Piece bishop) {
    return _getLinearMoves(board, bishop, [
      const Position(1, 1), // up-right
      const Position(1, -1), // down-right
      const Position(-1, 1), // up-left
      const Position(-1, -1), // down-left
    ]);
  }

  static List<Position> _getQueenMoves(Board board, Piece queen) {
    return [
      ..._getRookMoves(board, queen),
      ..._getBishopMoves(board, queen),
    ];
  }

  static List<Position> _getKingMoves(Board board, Piece king) {
    final moves = <Position>[];
    final position = king.position;

    for (int fileOffset = -1; fileOffset <= 1; fileOffset++) {
      for (int rankOffset = -1; rankOffset <= 1; rankOffset++) {
        if (fileOffset == 0 && rankOffset == 0) continue;

        final newPos =
            Position(position.file + fileOffset, position.rank + rankOffset);
        if (newPos.isValid) {
          final targetPiece = board.getPieceAt(newPos);
          if (targetPiece == null || targetPiece.color != king.color) {
            moves.add(newPos);
          }
        }
      }
    }

    return moves;
  }

  static List<Position> _getLinearMoves(
      Board board, Piece piece, List<Position> directions) {
    final moves = <Position>[];
    final position = piece.position;

    for (final direction in directions) {
      var currentPos = position;

      while (true) {
        currentPos = Position(
            currentPos.file + direction.file, currentPos.rank + direction.rank);
        if (!currentPos.isValid) break;

        final targetPiece = board.getPieceAt(currentPos);
        if (targetPiece == null) {
          moves.add(currentPos);
        } else {
          if (targetPiece.color != piece.color) {
            moves.add(currentPos);
          }
          break;
        }
      }
    }

    return moves;
  }

  static bool _isMoveLegal(Board board, Piece piece, Position target) {
    // Simulate the move
    final simulatedBoard = board.movePiece(piece, target);

    // Check if own king is in check after the move
    return !_isKingInCheck(simulatedBoard, piece.color);
  }

  static bool _isKingInCheck(Board board, PieceColor kingColor) {
    final king = board.findKing(kingColor);
    if (king == null) return false;

    final opponentColor = kingColor.opposite;
    final opponentPieces = board.getPiecesByColor(opponentColor);

    for (final opponentPiece in opponentPieces) {
      final opponentMoves =
          _getPotentialMoves(board, opponentPiece, opponentPiece.currentType);
      for (final move in opponentMoves) {
        if (move.file == king.position.file &&
            move.rank == king.position.rank) {
          return true;
        }
      }
    }

    return false;
  }

  static GameState getGameState(Board board) {
    final currentPlayer = board.currentTurn;

    // Check if king is in check
    final isInCheck = _isKingInCheck(board, currentPlayer);

    // Check if player has any legal moves
    final hasLegalMoves = _hasAnyLegalMoves(board, currentPlayer);

    if (!hasLegalMoves) {
      return isInCheck ? GameState.checkmate : GameState.stalemate;
    }

    return isInCheck ? GameState.check : GameState.active;
  }

  static bool _hasAnyLegalMoves(Board board, PieceColor color) {
    final pieces = board.getPiecesByColor(color);

    for (final piece in pieces) {
      final validMoves = getValidMoves(board, piece);
      if (validMoves.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  static bool isValidMove(Board board, Piece piece, Position target) {
    final validMoves = getValidMoves(board, piece);
    return validMoves
        .any((move) => move.file == target.file && move.rank == target.rank);
  }

  static Move createMove(Board board, Piece piece, Position target) {
    final targetPiece = board.getPieceAt(target);
    final isCapture = targetPiece != null && targetPiece.color != piece.color;

    // Check if move puts opponent in check
    final simulatedBoard = board.movePiece(piece, target);
    final isCheck = _isKingInCheck(simulatedBoard, piece.color.opposite);

    // Check for checkmate (simplified - would need more logic)
    final isCheckmate =
        isCheck && !_hasAnyLegalMoves(simulatedBoard, piece.color.opposite);

    return Move.fromPiece(
      piece: piece,
      to: target,
      isCapture: isCapture,
      capturedPiece: targetPiece,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
    );
  }
}
