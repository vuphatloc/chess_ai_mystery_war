enum PieceColor {
  white,
  black,
}

extension PieceColorExtension on PieceColor {
  String get symbol {
    switch (this) {
      case PieceColor.white:
        return 'W';
      case PieceColor.black:
        return 'B';
    }
  }

  String get name {
    switch (this) {
      case PieceColor.white:
        return 'White';
      case PieceColor.black:
        return 'Black';
    }
  }

  PieceColor get opposite {
    switch (this) {
      case PieceColor.white:
        return PieceColor.black;
      case PieceColor.black:
        return PieceColor.white;
    }
  }
}
