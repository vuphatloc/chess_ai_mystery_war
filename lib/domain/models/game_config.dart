import '../value_objects/piece_color.dart';

/// All configuration for a single game session.
/// Passed from GameSetupScreen → GameScreen.

enum GameMode { normal, mystery, champion }

enum PlayerCount { one, two }

enum BotDifficulty {
  beginner(400, 600),
  novice(600, 900),
  intermediate(900, 1200),
  advanced(1200, 1500),
  expert(1500, 1800),
  master(1800, 2100),
  grandmaster(2100, 2500);

  final int eloMin;
  final int eloMax;
  const BotDifficulty(this.eloMin, this.eloMax);
  String get eloLabel => '$eloMin–$eloMax Elo';
}

enum TimeControl {
  unlimited(0, 0),
  blitz3(3, 0),
  blitz3inc2(3, 2),
  blitz5(5, 0),
  blitz5inc3(5, 3),
  blitz10(10, 0);

  final int minutes;
  final int incrementSec;
  const TimeControl(this.minutes, this.incrementSec);

  bool get isUnlimited => minutes == 0;

  String label(String minStr, String incStr) {
    if (isUnlimited) return '';
    if (incrementSec == 0) return '$minutes $minStr';
    return '$minutes+$incrementSec $incStr';
  }
}

enum MysterySubType {
  hiddenIdentity,
  fogOfWar,
  blindfold,
  doubleBlind,
}

enum ChampionSubType { normal, mystery }

enum ChampionSession { newCampaign, continueCampaign }

class GameConfig {
  final GameMode mode;
  final PlayerCount playerCount;
  final BotDifficulty botDifficulty;
  final TimeControl timeControl;
  final MysterySubType? mysterySubType;
  final ChampionSubType? championSubType;
  final ChampionSession? championSession;
  /// Color the human player controls (white by default). Bot plays the opposite.
  final PieceColor playerColor;

  const GameConfig({
    required this.mode,
    this.playerCount = PlayerCount.one,
    this.botDifficulty = BotDifficulty.intermediate,
    this.timeControl = TimeControl.unlimited,
    this.mysterySubType,
    this.championSubType,
    this.championSession,
    this.playerColor = PieceColor.white,
  });

  bool get isOnePlayer => playerCount == PlayerCount.one;
  bool get hasTimeLimit => !timeControl.isUnlimited;
  PieceColor get botColor => playerColor.opposite;
}
