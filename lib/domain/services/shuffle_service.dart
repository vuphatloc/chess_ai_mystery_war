import 'dart:math';

import '../value_objects/position.dart';
import '../value_objects/piece_type.dart';
import '../value_objects/piece_color.dart';
import '../entities/piece.dart';
import '../entities/board.dart';

class ShuffleService {
  static Board shuffleBoard(Board board) {
    final random = Random();
    final squares = List.generate(8, (_) => List<Piece?>.filled(8, null));

    // Get all pieces except kings (kings stay in place and revealed)
    final whitePieces = board.getPiecesByColor(PieceColor.white);
    final blackPieces = board.getPiecesByColor(PieceColor.black);

    final whiteNonKings =
        whitePieces.where((p) => p.actualType != PieceType.king).toList();
    final blackNonKings =
        blackPieces.where((p) => p.actualType != PieceType.king).toList();

    // Shuffle the pieces
    whiteNonKings.shuffle(random);
    blackNonKings.shuffle(random);

    // Place kings in their standard positions (revealed)
    final whiteKing =
        whitePieces.firstWhere((p) => p.actualType == PieceType.king);
    final blackKing =
        blackPieces.firstWhere((p) => p.actualType == PieceType.king);

    squares[whiteKing.position.rank][whiteKing.position.file] = whiteKing;
    squares[blackKing.position.rank][blackKing.position.file] = blackKing;

    // Place shuffled pieces in standard starting positions
    _placeShuffledPieces(squares, whiteNonKings, PieceColor.white, random);
    _placeShuffledPieces(squares, blackNonKings, PieceColor.black, random);

    return Board(squares: squares);
  }

  static void _placeShuffledPieces(
    List<List<Piece?>> squares,
    List<Piece> pieces,
    PieceColor color,
    Random random,
  ) {
    final startRank = color == PieceColor.white ? 0 : 7;
    final pawnRank = color == PieceColor.white ? 1 : 6;

    // Standard chess piece positions
    final piecePositions = [
      Position(0, startRank), // rook
      Position(1, startRank), // knight
      Position(2, startRank), // bishop
      Position(3, startRank), // queen
      Position(4, startRank), // king (already placed)
      Position(5, startRank), // bishop
      Position(6, startRank), // knight
      Position(7, startRank), // rook
    ];

    // Place non-king pieces
    int pieceIndex = 0;
    for (final position in piecePositions) {
      // Skip king position (file 4)
      if (position.file == 4) continue;

      if (pieceIndex < pieces.length) {
        final piece = pieces[pieceIndex];
        final shuffledPiece = piece.copyWith(
          position: position,
          isRevealed: false,
          apparentType: Piece.getApparentTypeFromPosition(position, color),
        );
        squares[position.rank][position.file] = shuffledPiece;
        pieceIndex++;
      }
    }

    // Place pawns
    for (int file = 0; file < 8; file++) {
      if (pieceIndex < pieces.length) {
        final piece = pieces[pieceIndex];
        final pawnPosition = Position(file, pawnRank);
        final shuffledPiece = piece.copyWith(
          position: pawnPosition,
          isRevealed: false,
          apparentType: Piece.getApparentTypeFromPosition(pawnPosition, color),
        );
        squares[pawnPosition.rank][pawnPosition.file] = shuffledPiece;
        pieceIndex++;
      }
    }
  }

  static Board createRandomBoard() {
    final random = Random();
    final squares = List.generate(8, (_) => List<Piece?>.filled(8, null));

    // Create standard piece set
    final whitePieces = _createStandardPieceSet(PieceColor.white);
    final blackPieces = _createStandardPieceSet(PieceColor.black);

    // Shuffle both sets
    whitePieces.shuffle(random);
    blackPieces.shuffle(random);

    // Place kings (revealed)
    final whiteKing =
        whitePieces.firstWhere((p) => p.actualType == PieceType.king);
    final blackKing =
        blackPieces.firstWhere((p) => p.actualType == PieceType.king);

    squares[0][4] =
        whiteKing.copyWith(position: Position(4, 0), isRevealed: true);
    squares[7][4] =
        blackKing.copyWith(position: Position(4, 7), isRevealed: true);

    // Remove kings from lists
    whitePieces.removeWhere((p) => p.actualType == PieceType.king);
    blackPieces.removeWhere((p) => p.actualType == PieceType.king);

    // Place remaining pieces
    _placeRandomPieces(squares, whitePieces, PieceColor.white, random);
    _placeRandomPieces(squares, blackPieces, PieceColor.black, random);

    return Board(squares: squares);
  }

  static List<Piece> _createStandardPieceSet(PieceColor color) {
    return [
      Piece.create(
          actualType: PieceType.rook, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.knight, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.bishop, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.queen, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.king, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.bishop, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.knight, color: color, position: Position(0, 0)),
      Piece.create(
          actualType: PieceType.rook, color: color, position: Position(0, 0)),
      ...List.generate(
          8,
          (_) => Piece.create(
                actualType: PieceType.pawn,
                color: color,
                position: Position(0, 0),
              )),
    ];
  }

  static void _placeRandomPieces(
    List<List<Piece?>> squares,
    List<Piece> pieces,
    PieceColor color,
    Random random,
  ) {
    final startRank = color == PieceColor.white ? 0 : 7;
    final pawnRank = color == PieceColor.white ? 1 : 6;

    // Standard positions (excluding king at file 4)
    final piecePositions = [
      Position(0, startRank),
      Position(1, startRank),
      Position(2, startRank),
      Position(3, startRank),
      Position(5, startRank),
      Position(6, startRank),
      Position(7, startRank),
    ];

    // Shuffle positions
    final shuffledPositions = List<Position>.from(piecePositions);
    shuffledPositions.shuffle(random);

    // Place non-pawn pieces
    int pieceIndex = 0;
    for (final position in shuffledPositions) {
      if (pieceIndex < pieces.length &&
          pieces[pieceIndex].actualType != PieceType.pawn) {
        final piece = pieces[pieceIndex];
        squares[position.rank][position.file] = piece.copyWith(
          position: position,
          isRevealed: false,
        );
        pieceIndex++;
      }
    }

    // Place pawns
    final pawnFiles = List.generate(8, (i) => i);
    pawnFiles.shuffle(random);

    for (final file in pawnFiles) {
      if (pieceIndex < pieces.length) {
        final piece = pieces[pieceIndex];
        if (piece.actualType == PieceType.pawn) {
          final position = Position(file, pawnRank);
          squares[position.rank][position.file] = piece.copyWith(
            position: position,
            isRevealed: false,
          );
          pieceIndex++;
        }
      }
    }

    // Place any remaining pieces randomly
    while (pieceIndex < pieces.length) {
      final piece = pieces[pieceIndex];
      final emptyPositions = _getEmptyPositions(squares);
      if (emptyPositions.isEmpty) break;

      final position = emptyPositions[random.nextInt(emptyPositions.length)];
      squares[position.rank][position.file] = piece.copyWith(
        position: position,
        isRevealed: false,
      );
      pieceIndex++;
    }
  }

  static List<Position> _getEmptyPositions(List<List<Piece?>> squares) {
    final positions = <Position>[];
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        if (squares[rank][file] == null) {
          positions.add(Position(file, rank));
        }
      }
    }
    return positions;
  }
}
