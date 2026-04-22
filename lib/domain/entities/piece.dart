import 'package:equatable/equatable.dart';

import '../value_objects/piece_type.dart';
import '../value_objects/piece_color.dart';
import '../value_objects/position.dart';

class Piece extends Equatable {
  final PieceType actualType;
  final PieceColor color;
  final Position position;
  final bool isRevealed;
  final PieceType apparentType;

  const Piece({
    required this.actualType,
    required this.color,
    required this.position,
    required this.isRevealed,
    required this.apparentType,
  });

  factory Piece.create({
    required PieceType actualType,
    required PieceColor color,
    required Position position,
    bool isRevealed = false,
  }) {
    return Piece(
      actualType: actualType,
      color: color,
      position: position,
      isRevealed: isRevealed,
      apparentType: isRevealed
          ? actualType
          : _getApparentTypeFromPosition(position, color),
    );
  }

  static PieceType _getApparentTypeFromPosition(
      Position position, PieceColor color) {
    // In standard chess starting position:
    // Rooks at a1/h1 (white) and a8/h8 (black)
    // Knights at b1/g1 (white) and b8/g8 (black)
    // Bishops at c1/f1 (white) and c8/f8 (black)
    // Queen at d1 (white) and d8 (black)
    // King at e1 (white) and e8 (black)
    // Pawns at rank 2 (white) and rank 7 (black)

    if (color == PieceColor.white) {
      if (position.rank == 0) {
        // First rank for white
        if (position.file == 0 || position.file == 7) return PieceType.rook;
        if (position.file == 1 || position.file == 6) return PieceType.knight;
        if (position.file == 2 || position.file == 5) return PieceType.bishop;
        if (position.file == 3) return PieceType.queen;
        if (position.file == 4) return PieceType.king;
      } else if (position.rank == 1) {
        // Second rank for white pawns
        return PieceType.pawn;
      }
    } else {
      // black
      if (position.rank == 7) {
        // Eighth rank for black
        if (position.file == 0 || position.file == 7) return PieceType.rook;
        if (position.file == 1 || position.file == 6) return PieceType.knight;
        if (position.file == 2 || position.file == 5) return PieceType.bishop;
        if (position.file == 3) return PieceType.queen;
        if (position.file == 4) return PieceType.king;
      } else if (position.rank == 6) {
        // Seventh rank for black pawns
        return PieceType.pawn;
      }
    }

    // For other positions (shouldn't happen in standard setup)
    return PieceType.pawn;
  }

  Piece copyWith({
    PieceType? actualType,
    PieceColor? color,
    Position? position,
    bool? isRevealed,
    PieceType? apparentType,
  }) {
    return Piece(
      actualType: actualType ?? this.actualType,
      color: color ?? this.color,
      position: position ?? this.position,
      isRevealed: isRevealed ?? this.isRevealed,
      apparentType: apparentType ?? this.apparentType,
    );
  }

  Piece moveTo(Position newPosition) {
    return copyWith(
      position: newPosition,
      isRevealed: true, // Piece is revealed after moving
    );
  }

  Piece reveal() {
    return copyWith(
      isRevealed: true,
      apparentType: actualType,
    );
  }

  PieceType get currentType => isRevealed ? actualType : apparentType;

  @override
  List<Object?> get props => [
        actualType,
        color,
        position,
        isRevealed,
        apparentType,
      ];

  @override
  String toString() {
    return 'Piece(${color.symbol}${currentType.symbol}@${position.toAlgebraic()} ${isRevealed ? 'revealed' : 'hidden'})';
  }
}
