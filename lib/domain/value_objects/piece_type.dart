enum PieceType {
  pawn,
  rook,
  knight,
  bishop,
  queen,
  king,
}

extension PieceTypeExtension on PieceType {
  String get symbol {
    switch (this) {
      case PieceType.pawn:
        return 'P';
      case PieceType.rook:
        return 'R';
      case PieceType.knight:
        return 'N';
      case PieceType.bishop:
        return 'B';
      case PieceType.queen:
        return 'Q';
      case PieceType.king:
        return 'K';
    }
  }

  String get name {
    switch (this) {
      case PieceType.pawn:
        return 'Pawn';
      case PieceType.rook:
        return 'Rook';
      case PieceType.knight:
        return 'Knight';
      case PieceType.bishop:
        return 'Bishop';
      case PieceType.queen:
        return 'Queen';
      case PieceType.king:
        return 'King';
    }
  }
}
