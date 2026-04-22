import 'package:equatable/equatable.dart';

class Position extends Equatable {
  final int file; // 0-7 (a-h)
  final int rank; // 0-7 (1-8)

  const Position(this.file, this.rank);

  factory Position.fromAlgebraic(String algebraic) {
    if (algebraic.length != 2) {
      throw ArgumentError('Algebraic notation must be 2 characters');
    }
    final fileChar = algebraic[0].toLowerCase();
    final rankChar = algebraic[1];

    final file = fileChar.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(rankChar) - 1;

    return Position(file, rank);
  }

  String toAlgebraic() {
    final fileChar = String.fromCharCode('a'.codeUnitAt(0) + file);
    return '$fileChar${rank + 1}';
  }

  bool get isValid => file >= 0 && file < 8 && rank >= 0 && rank < 8;

  Position copyWith({
    int? file,
    int? rank,
  }) {
    return Position(
      file ?? this.file,
      rank ?? this.rank,
    );
  }

  @override
  List<Object?> get props => [file, rank];

  @override
  String toString() => toAlgebraic();
}
