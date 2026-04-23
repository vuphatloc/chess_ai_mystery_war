import 'package:audioplayers/audioplayers.dart';
import '../../domain/models/game_config.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AudioService — manages BGM + SFX per music_sound.md spec.
///
/// BGM: looping background music per game mode (Dark Jazz, Ambient, Lo-fi...)
/// SFX: one-shot effects (move, capture, reveal, fog, check, win/lose...)
///
/// Settings: musicEnabled & sfxEnabled from UserSettings (injected via setters).
/// ─────────────────────────────────────────────────────────────────────────────
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _sfx2Player = AudioPlayer(); // secondary channel for overlapping sfx

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  String? _currentBgm;

  // ── Settings ──────────────────────────────────────────────────────────────

  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _bgmPlayer.stop();
    } else if (_currentBgm != null) {
      _playBgm(_currentBgm!);
    }
  }

  void setSfxEnabled(bool enabled) => _sfxEnabled = enabled;

  // ── BGM Control ───────────────────────────────────────────────────────────

  /// Play the correct BGM for the given [config]. Loops automatically.
  Future<void> playBgmForMode(GameConfig config) async {
    final file = _bgmFileFor(config);
    if (_currentBgm == file) return; // already playing
    _currentBgm = file;
    await _playBgm(file);
  }

  Future<void> _playBgm(String assetPath) async {
    if (!_musicEnabled) return;
    await _bgmPlayer.stop();
    await _bgmPlayer.setVolume(0.45);
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource(assetPath));
  }

  /// Fade out and stop BGM (e.g. when leaving game).
  Future<void> stopBgm() async {
    _currentBgm = null;
    await _bgmPlayer.stop();
  }

  /// Fade BGM volume down when blindfold activates (per music_sound.md spec).
  Future<void> fadeOutBgm() async {
    for (double v = 0.45; v >= 0; v -= 0.05) {
      await _bgmPlayer.setVolume(v.clamp(0, 1));
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> fadeInBgm() async {
    for (double v = 0; v <= 0.45; v += 0.05) {
      await _bgmPlayer.setVolume(v.clamp(0, 1));
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  // ── SFX ───────────────────────────────────────────────────────────────────

  Future<void> playMove() => _sfx(SfxType.move);
  Future<void> playMoveHidden() => _sfx(SfxType.moveHidden);
  Future<void> playCapture() => _sfx(SfxType.capture);
  Future<void> playRevealStrong() => _sfx(SfxType.revealStrong);
  Future<void> playRevealWeak() => _sfx(SfxType.revealWeak);
  Future<void> playCheck() => _sfx(SfxType.check);
  Future<void> playCheckmate() => _sfx(SfxType.checkmate);
  Future<void> playFogEnter() => _sfx(SfxType.fogEnter);
  Future<void> playFogDiscover() => _sfx(SfxType.fogDiscover);
  Future<void> playFogAttack() => _sfx2Sfx(SfxType.fogAttack);
  Future<void> playBlindfoldHide() => _sfx(SfxType.blindfoldHide);
  Future<void> playBlindfoldClick() => _sfx(SfxType.blindfoldClick);
  Future<void> playBlindfoldWrong() => _sfx(SfxType.blindfoldWrong);
  Future<void> playWin() => _sfx(SfxType.win);
  Future<void> playLose() => _sfx(SfxType.lose);
  Future<void> playGold() => _sfx(SfxType.gold);
  Future<void> playButton() => _sfx(SfxType.button);
  Future<void> playTimerTick() => _sfx(SfxType.timerTick);

  Future<void> _sfx(SfxType type) async {
    if (!_sfxEnabled) return;
    final path = _sfxPath(type);
    await _sfxPlayer.stop();
    await _sfxPlayer.setVolume(0.8);
    await _sfxPlayer.play(AssetSource(path));
  }

  Future<void> _sfx2Sfx(SfxType type) async {
    if (!_sfxEnabled) return;
    final path = _sfxPath(type);
    await _sfx2Player.stop();
    await _sfx2Player.setVolume(0.85);
    await _sfx2Player.play(AssetSource(path));
  }

  // ── Smart move sound dispatcher ──────────────────────────────────────────

  /// Call after every move — picks the right SFX automatically.
  Future<void> onMove({
    required bool isCapture,
    required bool isReveal,
    required bool isCheck,
    required bool isCheckmate,
    required bool isHiddenPiece,
    required bool isStrongReveal, // Queen/Rook reveal = strong sound
    required bool isFogDiscover,
  }) async {
    if (isCheckmate) {
      await playCheckmate();
    } else if (isCheck) {
      await playCheck();
    } else if (isReveal) {
      if (isStrongReveal) {
        await playRevealStrong();
      } else {
        await playRevealWeak();
      }
    } else if (isCapture) {
      await playCapture();
    } else if (isHiddenPiece) {
      await playMoveHidden();
    } else if (isFogDiscover) {
      await playFogDiscover();
    } else {
      await playMove();
    }
  }

  // ── Asset path resolvers ──────────────────────────────────────────────────

  String _bgmFileFor(GameConfig config) {
    if (config.mode == GameMode.champion) return 'audio/bgm/bgm_champion.mp3';
    if (config.mode == GameMode.normal)   return 'audio/bgm/bgm_normal.mp3';

    switch (config.mysterySubType) {
      case MysterySubType.hiddenIdentity: return 'audio/bgm/bgm_hidden.mp3';
      case MysterySubType.fogOfWar:       return 'audio/bgm/bgm_fog.mp3';
      case MysterySubType.blindfold:      return 'audio/bgm/bgm_blindfold.mp3';
      case MysterySubType.doubleBlind:    return 'audio/bgm/bgm_double_blind.mp3';
      case null:                           return 'audio/bgm/bgm_normal.mp3';
    }
  }

  String _sfxPath(SfxType type) {
    switch (type) {
      case SfxType.move:           return 'audio/sfx/sfx_move.mp3';
      case SfxType.moveHidden:     return 'audio/sfx/sfx_move_hidden.mp3';
      case SfxType.capture:        return 'audio/sfx/sfx_capture.mp3';
      case SfxType.revealStrong:   return 'audio/sfx/sfx_reveal_strong.mp3';
      case SfxType.revealWeak:     return 'audio/sfx/sfx_reveal_weak.mp3';
      case SfxType.check:          return 'audio/sfx/sfx_check.mp3';
      case SfxType.checkmate:      return 'audio/sfx/sfx_checkmate.mp3';
      case SfxType.fogEnter:       return 'audio/sfx/sfx_fog_enter.mp3';
      case SfxType.fogDiscover:    return 'audio/sfx/sfx_fog_discover.mp3';
      case SfxType.fogAttack:      return 'audio/sfx/sfx_fog_attack.mp3';
      case SfxType.blindfoldHide:  return 'audio/sfx/sfx_blindfold_hide.mp3';
      case SfxType.blindfoldClick: return 'audio/sfx/sfx_blindfold_click.mp3';
      case SfxType.blindfoldWrong: return 'audio/sfx/sfx_blindfold_wrong.mp3';
      case SfxType.win:            return 'audio/sfx/sfx_win.mp3';
      case SfxType.lose:           return 'audio/sfx/sfx_lose.mp3';
      case SfxType.gold:           return 'audio/sfx/sfx_gold.mp3';
      case SfxType.button:         return 'audio/sfx/sfx_button.mp3';
      case SfxType.timerTick:      return 'audio/sfx/sfx_timer_tick.mp3';
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _sfx2Player.dispose();
  }
}

enum SfxType {
  move,
  moveHidden,
  capture,
  revealStrong,
  revealWeak,
  check,
  checkmate,
  fogEnter,
  fogDiscover,
  fogAttack,
  blindfoldHide,
  blindfoldClick,
  blindfoldWrong,
  win,
  lose,
  gold,
  button,
  timerTick,
}
