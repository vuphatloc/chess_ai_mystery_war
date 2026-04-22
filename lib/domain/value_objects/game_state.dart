enum GameState {
  active,
  check,
  checkmate,
  stalemate,
  draw,
}

extension GameStateExtension on GameState {
  String get description {
    switch (this) {
      case GameState.active:
        return 'Game in progress';
      case GameState.check:
        return 'Check';
      case GameState.checkmate:
        return 'Checkmate';
      case GameState.stalemate:
        return 'Stalemate';
      case GameState.draw:
        return 'Draw';
    }
  }
}
