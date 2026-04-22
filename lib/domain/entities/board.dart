import 'package:equatable/equatable.dart';

import '../value_objects/position.dart';
import '../value_objects/piece_color.dart';
import '../value_objects/piece_type.dart';
import 'piece.dart';
import 'move.dart';

class Board extends Equatable {
  final List<List<Piece?>> squares; // 8x8 grid
  final PieceColor currentTurn;
  final List<Move> moveHistory;

  const Board({
    required this.squares,
    this.currentTurn = PieceColor.white,
    this.moveHistory = const [],
  });

  factory Board.initial() {
    final squares = List.generate(8, (_) => List<Piece?>.filled(8, null));

    // Create standard chess pieces (all hidden except kings)
    final whitePieces = [
      Piece.create(
          actualType: PieceType.rook,
          color: PieceColor.white,
          position: Position(0, 0),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.knight,
          color: PieceColor.white,
          position: Position(1, 0),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.bishop,
          color: PieceColor.white,
          position: Position(2, 0),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.queen,
          color: PieceColor.white,
          position: Position(3, 0),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.king,
          color: PieceColor.white,
          position: Position(4, 0),
          isRevealed: true), // King revealed
      Piece.create(
          actualType: PieceType.bishop,
          color: PieceColor.white,
          position: Position(5, 0),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.knight,
          color: PieceColor.white,
          position: Position(6, 0),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.rook,
          color: PieceColor.white,
          position: Position(7, 0),
          isRevealed: false),
    ];

    final blackPieces = [
      Piece.create(
          actualType: PieceType.rook,
          color: PieceColor.black,
          position: Position(0, 7),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.knight,
          color: PieceColor.black,
          position: Position(1, 7),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.bishop,
          color: PieceColor.black,
          position: Position(2, 7),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.queen,
          color: PieceColor.black,
          position: Position(3, 7),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.king,
          color: PieceColor.black,
          position: Position(4, 7),
          isRevealed: true), // King revealed
      Piece.create(
          actualType: PieceType.bishop,
          color: PieceColor.black,
          position: Position(5, 7),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.knight,
          color: PieceColor.black,
          position: Position(6, 7),
          isRevealed: false),
      Piece.create(
          actualType: PieceType.rook,
          color: PieceColor.black,
          position: Position(7, 7),
          isRevealed: false),
    ];

    // Add pawns
    for (int file = 0; file < 8; file++) {
      whitePieces.add(Piece.create(
        actualType: PieceType.pawn,
        color: PieceColor.white,
        position: Position(file, 1),
        isRevealed: false,
      ));
      blackPieces.add(Piece.create(
        actualType: PieceType.pawn,
        color: PieceColor.black,
        position: Position(file, 6),
        isRevealed: false,
      ));
    }

    // Place all pieces on board
    for (final piece in [...whitePieces, ...blackPieces]) {
      squares[piece.position.rank][piece.position.file] = piece;
    }

    return Board(squares: squares);
  }

  Piece? getPieceAt(Position position) {
    if (!position.isValid) return null;
    return squares[position.rank][position.file];
  }

  Board copyWith({
    List<List<Piece?>>? squares,
    PieceColor? currentTurn,
    List<Move>? moveHistory,
  }) {
    return Board(
      squares: squares ?? this.squares,
      currentTurn: currentTurn ?? this.currentTurn,
      moveHistory: moveHistory ?? this.moveHistory,
    );
  }

  Board placePiece(Piece piece) {
    final newSquares =
        List.generate(8, (rank) => List<Piece?>.from(squares[rank]));
    newSquares[piece.position.rank][piece.position.file] = piece;
    return copyWith(squares: newSquares);
  }

  Board removePieceAt(Position position) {
    final newSquares =
        List.generate(8, (rank) => List<Piece?>.from(squares[rank]));
    newSquares[position.rank][position.file] = null;
    return copyWith(squares: newSquares);
  }

  Board movePiece(Piece piece, Position to) {
    final newSquares =
        List.generate(8, (rank) => List<Piece?>.from(squares[rank]));

    // Remove piece from old position
    newSquares[piece.position.rank][piece.position.file] = null;

    // Place piece at new position (revealed after move)
    final movedPiece = piece.moveTo(to);
    newSquares[to.rank][to.file] = movedPiece;

    return copyWith(
      squares: newSquares,
      currentTurn: currentTurn.opposite,
    );
  }

  List<Piece> getPiecesByColor(PieceColor color) {
    final pieces = <Piece>[];
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = squares[rank][file];
        if (piece != null && piece.color == color) {
          pieces.add(piece);
        }
      }
    }
    return pieces;
  }

  Piece? findKing(PieceColor color) {
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = squares[rank][file];
        if (piece != null &&
            piece.color == color &&
            piece.actualType == PieceType.king) {
          return piece;
        }
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [squares, currentTurn, moveHistory];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Current turn: ${currentTurn.name}');
    buffer.writeln('  a b c d e f g h');
    for (int rank = 7; rank >= 0; rank--) {
      buffer.write('${rank + 1} ');
      for (int file = 0; file < 8; file++) {
        final piece = squares[rank][file];
        if (piece == null) {
          buffer.write('. ');
        } else {
          final symbol = piece.currentType.symbol;
          buffer.write(
              '${piece.color == PieceColor.white ? symbol.toUpperCase() : symbol.toLowerCase()} ');
        }
      }
      buffer.writeln('${rank + 1}');
    }
    buffer.writeln('  a b c d e f g h');
    return buffer.toString();
  }
}
