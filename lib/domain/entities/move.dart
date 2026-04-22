import 'package:equatable/equatable.dart';

import '../value_objects/position.dart';
import '../value_objects/piece_type.dart';
import 'piece.dart';

class Move extends Equatable {
  final Position from;
  final Position to;
  final PieceType pieceType;
  final bool isCapture;
  final Piece? capturedPiece;
  final bool isCheck;
  final bool isCheckmate;
  final bool isPromotion;
  final PieceType? promotionType;

  const Move({
    required this.from,
    required this.to,
    required this.pieceType,
    this.isCapture = false,
    this.capturedPiece,
    this.isCheck = false,
    this.isCheckmate = false,
    this.isPromotion = false,
    this.promotionType,
  });

  factory Move.fromPiece({
    required Piece piece,
    required Position to,
    bool isCapture = false,
    Piece? capturedPiece,
    bool isCheck = false,
    bool isCheckmate = false,
    bool isPromotion = false,
    PieceType? promotionType,
  }) {
    return Move(
      from: piece.position,
      to: to,
      pieceType: piece.currentType,
      isCapture: isCapture,
      capturedPiece: capturedPiece,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isPromotion: isPromotion,
      promotionType: promotionType,
    );
  }

  String toAlgebraic() {
    final pieceSymbol = pieceType.symbol;
    final captureSymbol = isCapture ? 'x' : '';
    final destination = to.toAlgebraic();
    final checkSymbol = isCheckmate ? '#' : (isCheck ? '+' : '');

    return '$pieceSymbol$captureSymbol$destination$checkSymbol';
  }

  @override
  List<Object?> get props => [
        from,
        to,
        pieceType,
        isCapture,
        capturedPiece,
        isCheck,
        isCheckmate,
        isPromotion,
        promotionType,
      ];

  @override
  String toString() => toAlgebraic();
}
