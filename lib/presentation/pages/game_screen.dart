import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../domain/models/game_config.dart';
import '../../../domain/models/skin_registry.dart';
import '../../../domain/providers/user_provider.dart';
import '../../../domain/services/game_mode_manager.dart';
import '../../../domain/services/blitz_timer_service.dart';
import '../../../domain/services/bot_service.dart';
import '../../../domain/services/audio_service.dart';
import '../widgets/chess_piece_widget.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/move.dart';
import '../../domain/entities/game_rules_engine.dart';
import '../../domain/services/shuffle_service.dart';
import '../../domain/value_objects/position.dart';
import '../../domain/value_objects/piece_color.dart';
import '../../domain/value_objects/piece_type.dart';
import '../../domain/value_objects/game_state.dart';

class GameScreen extends ConsumerStatefulWidget {
  final GameConfig config;
  const GameScreen({super.key, required this.config});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late Board _board;
  Piece? _selectedPiece;
  List<Position> _validMoves = [];
  Position? _lastMoved;
  int _totalMoves = 0;
  bool _botThinking = false;
  int _botGeneration = 0; // incremented on new game to invalidate pending bot futures
  bool _peekActive = false;
  Timer? _peekTimer;

  // Hint state
  Piece? _hintPiece;
  Position? _hintTarget;
  bool _hintGenerating = false;

  // Check banner
  bool _showCheckBanner = false;
  Timer? _checkBannerTimer;

  // Services
  late GameModeManager _modeManager;
  BlitzTimerService? _timerService;
  BotService? _botService;
  StreamSubscription<TimerEvent>? _timerSub;
  TimerEvent? _timerEvent;
  final AudioService _audio = AudioService();

  // Visibility
  VisibilityMap? _visMap;
  bool _blindfoldFaded = false;
  bool _audioReady = false; // true after settings synced; prevents premature BGM start

  @override
  void initState() {
    super.initState();
    _modeManager = GameModeManager.fromConfig(widget.config);
    if (widget.config.hasTimeLimit) {
      _timerService = BlitzTimerService(timeControl: widget.config.timeControl);
      _timerSub = _timerService!.events.listen(_onTimer);
    }
    if (widget.config.isOnePlayer) {
      _botService = BotService(
        difficulty: widget.config.botDifficulty,
        mysterySubType: widget.config.mysterySubType,
      );
    }
    // Sync audio settings then start BGM — must happen after settings load.
    // _newGame() is called first but skips BGM on first run (_audioReady = false).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Re-read provider after a microtask to let async _load() complete.
      await Future.microtask(() {});
      if (!mounted) return;
      final s = ref.read(userSettingsProvider);
      _audio.setMusicEnabled(s.musicEnabled);
      _audio.setSfxEnabled(s.sfxEnabled);
      setState(() => _audioReady = true);
      _audio.playBgmForMode(widget.config);
    });
    _newGame();
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    _timerService?.dispose();
    _peekTimer?.cancel();
    _checkBannerTimer?.cancel();
    _audio.stopBgm();
    super.dispose();
  }

  void _newGame() {
    _botGeneration++;
    setState(() {
      _board = Board.initial();
      final mode = widget.config.mode;
      final sub = widget.config.mysterySubType;
      if (mode == GameMode.mystery &&
          (sub == MysterySubType.hiddenIdentity ||
           sub == MysterySubType.doubleBlind)) {
        _board = ShuffleService.shuffleBoard(_board);
      }
      _selectedPiece = null;
      _validMoves = [];
      _lastMoved = null;
      _totalMoves = 0;
      _botThinking = false;
      _peekActive = false;
      _hintPiece = null;
      _hintTarget = null;
      _hintGenerating = false;
      _showCheckBanner = false;
      _updateVisibility();
    });
    _timerService?.reset(isWhiteTurn: true);
    if (widget.config.hasTimeLimit) {
      _timerService?.start(isWhiteTurn: true);
    }
    _blindfoldFaded = false;
    // On first game start, addPostFrameCallback handles BGM after settings sync.
    // On restarts (_audioReady = true), settings are already applied to the singleton.
    if (_audioReady) _audio.playBgmForMode(widget.config);
    // If player chose black, bot (white) goes first
    if (widget.config.isOnePlayer &&
        widget.config.playerColor == PieceColor.black) {
      _scheduleBot();
    }
  }

  void _onTimer(TimerEvent e) {
    if (!mounted) return;
    setState(() => _timerEvent = e);
    if (e.anyExpired) {
      _timerService?.pause();
      if (e.whiteExpired || e.blackExpired) _audio.playLose();
    } else if (e.whiteCritical || e.blackCritical) {
      // Heartbeat tick in critical time
      _audio.playTimerTick();
    }
  }

  void _updateVisibility() {
    // Always render fog from the human player's perspective in 1-player mode.
    final viewerColor = widget.config.isOnePlayer
        ? widget.config.playerColor
        : _board.currentTurn;
    _visMap = _modeManager.getVisibleSquares(_board, viewerColor);
  }

  bool _isFaceDown(Piece piece) {
    if (_peekActive) return false;
    final viewerColor = widget.config.isOnePlayer
        ? widget.config.playerColor
        : _board.currentTurn;
    return _modeManager.isPieceFaceDown(piece, viewerColor, _totalMoves);
  }

  void _onSquareTap(Position pos) {
    if (_botThinking) return;
    final isMyTurn = !widget.config.isOnePlayer ||
        _board.currentTurn == widget.config.playerColor;
    if (!isMyTurn) return;

    final piece = _board.getPieceAt(pos);
    if (_selectedPiece != null) {
      if (_validMoves.any((m) => m.file == pos.file && m.rank == pos.rank)) {
        _doMove(_selectedPiece!, pos);
        return;
      } else if (piece != null && piece.color == _board.currentTurn) {
        setState(() {
          _selectedPiece = piece;
          _validMoves = _modeManager.getAvailableMoves(_board, piece);
        });
        return;
      }
      setState(() { _selectedPiece = null; _validMoves = []; });
    } else if (piece != null && piece.color == _board.currentTurn) {
      setState(() {
        _selectedPiece = piece;
        _validMoves = _modeManager.getAvailableMoves(_board, piece);
      });
    }
  }

  void _doMove(Piece piece, Position target) {
    final targetPiece = _board.getPieceAt(target);
    final isCapture = targetPiece != null && targetPiece.color != piece.color;
    final wasHidden = !piece.isRevealed;
    // After move, piece will be revealed (Board.movePiece calls piece.moveTo → isRevealed=true)
    final newBoard = _board.movePiece(piece, target);
    final movedPiece = newBoard.getPieceAt(target);
    final isReveal = wasHidden && (movedPiece?.isRevealed ?? false);
    final isStrongReveal = isReveal &&
        (piece.actualType == PieceType.queen ||
         piece.actualType == PieceType.rook ||
         piece.actualType == PieceType.bishop);
    final gameState = GameRulesEngine.getGameState(newBoard);

    final moveRecord = Move.fromPiece(
      piece: piece,
      to: target,
      isCapture: isCapture,
      capturedPiece: targetPiece,
      isCheck: gameState == GameState.check,
      isCheckmate: gameState == GameState.checkmate,
    );

    Board updatedBoard = newBoard.copyWith(
      moveHistory: [..._board.moveHistory, moveRecord],
    );

    if (isCapture) {
      if (targetPiece.color == PieceColor.white) {
        updatedBoard = updatedBoard.copyWith(
            capturedWhitePieces: [..._board.capturedWhitePieces, targetPiece]);
      } else {
        updatedBoard = updatedBoard.copyWith(
            capturedBlackPieces: [..._board.capturedBlackPieces, targetPiece]);
      }
    }

    setState(() {
      _board = updatedBoard;
      _lastMoved = target;
      _totalMoves++;
      _selectedPiece = null;
      _validMoves = [];
      _hintPiece = null;
      _hintTarget = null;
      _updateVisibility();
    });

    // Check notification
    if (gameState == GameState.check) {
      _checkBannerTimer?.cancel();
      setState(() => _showCheckBanner = true);
      _checkBannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showCheckBanner = false);
      });
    } else {
      setState(() => _showCheckBanner = false);
    }

    // SFX dispatch
    _audio.onMove(
      isCapture: isCapture,
      isReveal: isReveal,
      isCheck: gameState == GameState.check,
      isCheckmate: gameState == GameState.checkmate,
      isHiddenPiece: wasHidden,
      isStrongReveal: isStrongReveal,
      isFogDiscover: false, // TODO: detect fog discovery
    );

    // Blindfold: fade BGM when pieces disappear
    if (_modeManager.isBlindfoldActive &&
        _totalMoves == 12 &&
        !_blindfoldFaded) {
      _blindfoldFaded = true;
      _audio.fadeOutBgm();
      _audio.playBlindfoldHide();
    }

    // Win/loss audio
    // After checkmate, currentTurn is the side that IS in checkmate (can't move).
    // Player wins if the side in checkmate is NOT the player's color.
    if (gameState == GameState.checkmate) {
      Future.delayed(const Duration(milliseconds: 600), () {
        final playerColor = widget.config.isOnePlayer
            ? widget.config.playerColor
            : null; // 2-player: no concept of "player" side
        final checkmatedColor = _board.currentTurn;
        if (playerColor == null) {
          // 2-player: just play win sound for whoever won
          _audio.playWin();
        } else if (checkmatedColor == playerColor) {
          _audio.playLose(); // player is checkmated
        } else {
          _audio.playWin(); // bot is checkmated
        }
      });
    }

    _timerService?.onMoveMade(nextIsWhiteTurn: _board.currentTurn == PieceColor.white);
    if (gameState == GameState.active || gameState == GameState.check) {
      _scheduleBot();
    }
  }

  void _scheduleBot() {
    if (!widget.config.isOnePlayer) return;
    if (_board.currentTurn != widget.config.botColor) return;
    final gen = _botGeneration;
    setState(() => _botThinking = true);
    _botService!.getBestMove(_board, widget.config.botColor).then((move) {
      if (!mounted || _botGeneration != gen) return;
      if (move == null) {
        setState(() => _botThinking = false);
        return;
      }
      _doMove(move.piece, move.target);
      setState(() => _botThinking = false);
    }).catchError((Object _) {
      if (!mounted) return;
      setState(() => _botThinking = false);
    });
  }

  void _activatePeek() {
    setState(() => _peekActive = true);
    _peekTimer?.cancel();
    _peekTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _peekActive = false);
    });
  }

  /// Whether the board should be rendered flipped (black's POV)
  bool get _isFlipped =>
      widget.config.isOnePlayer &&
      widget.config.playerColor == PieceColor.black;

  /// Use Hint: deduct gold, run minimax, auto-select piece + highlight target.
  Future<void> _useHint() async {
    if (_hintGenerating || _botThinking) return;
    final isMyTurn = !widget.config.isOnePlayer ||
        _board.currentTurn == widget.config.playerColor;
    if (!isMyTurn) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _modeColor.withValues(alpha: 0.5))),
        title: Row(children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppTheme.gold, size: 20),
          const SizedBox(width: 8),
          Text(S.get('hint_title'),
              style: AppTheme.titleMedium.copyWith(color: AppTheme.gold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(S.get('hint_computing'),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('💰', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(S.get('hint_cost_label'),
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.gold)),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.get('cancel'),
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold.withValues(alpha: 0.2),
              foregroundColor: AppTheme.gold,
              side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.get('use_hint')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Deduct gold
    final goldOk = await ref.read(goldProvider.notifier).spend(10);
    if (!goldOk) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.get('insufficient_gold'),
            style: AppTheme.labelSmall.copyWith(color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() => _hintGenerating = true);
    final move = await BotService.computeHint(_board, widget.config.playerColor)
        .catchError((_) => null);

    if (!mounted) return;
    if (move == null) {
      setState(() => _hintGenerating = false);
      return;
    }
    // Auto-select the hinted piece and show valid moves
    setState(() {
      _hintGenerating = false;
      _hintPiece = move.piece;
      _hintTarget = move.target;
      _selectedPiece = move.piece;
      _validMoves = _modeManager.getAvailableMoves(_board, move.piece);
    });
  }

  Color get _modeColor {
    final idx = ref.read(activeThemeIndexProvider);
    final theme = SkinRegistry.getTheme(idx);
    switch (widget.config.mode) {
      case GameMode.normal: return theme.primary;
      case GameMode.mystery: return AppTheme.neonPurple;
      case GameMode.champion: return AppTheme.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(languageProvider);
    final pieceSkinId = ref.watch(activePieceSkinProvider);
    final boardSkinId = ref.watch(activeBoardSkinProvider);
    final skin = SkinRegistry.getSkin(pieceSkinId);
    final boardSkin = SkinRegistry.getBoardSkin(boardSkinId);
    final settings = ref.watch(userSettingsProvider);
    final gameState = GameRulesEngine.getGameState(_board);
    final timerExpired = _timerEvent?.anyExpired ?? false;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient)),
          SafeArea(
            child: Column(
              children: [
                // Always reserve space for check banner to prevent board jump
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showCheckBanner
                      ? _buildCheckBanner()
                      : const SizedBox(height: 36), // match banner height
                ),
                _buildHeader(context),
                if (widget.config.hasTimeLimit && _timerEvent != null)
                  _buildTimerRow(_timerEvent!)
                else
                  _buildTurnRow(),
                const SizedBox(height: 8),
                Expanded(child: Center(child: _buildBoard(skin, boardSkin))),
                Visibility(
                  visible: _botThinking,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _modeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _modeColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _modeColor)),
                          const SizedBox(width: 8),
                          Text('Bot thinking…',
                              style: AppTheme.labelSmall.copyWith(color: _modeColor)),
                        ]),
                      ),
                    ),
                  ),
                ),
                _buildBottom(gameState),
              ],
            ),
          ),
          if (gameState == GameState.checkmate ||
              gameState == GameState.stalemate ||
              timerExpired)
            _buildGameOver(gameState, timerExpired),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppTheme.textSecondary, size: 20),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CHESS AI', style: AppTheme.labelSmall),
            Row(children: [
              _modeBadge(_modeLabel, _modeColor),
              if (widget.config.hasTimeLimit) ...[
                const SizedBox(width: 6),
                _modeBadge('⚡ ${widget.config.timeControl.minutes}min',
                    Colors.orange),
              ],
              if (widget.config.isOnePlayer) ...[
                const SizedBox(width: 6),
                _modeBadge('vs BOT ${widget.config.botDifficulty.eloLabel}',
                    AppTheme.gold),
              ],
            ]),
          ]),
          const Spacer(),
          if (_modeManager.isBlindfoldActive)
            IconButton(
              onPressed: _activatePeek,
              icon: Icon(Icons.visibility_rounded,
                  color: _peekActive ? Colors.amber : AppTheme.textMuted),
              tooltip: 'Peek (2s)',
            ),
          // Hint button (1-player mode, player's turn, hints enabled)
          if (widget.config.isOnePlayer && settings.hintsEnabled)
            IconButton(
              onPressed: _hintGenerating
                  ? null
                  : () => _useHint(),
              tooltip: '${S.get("hint")} (10 Gold)',
              icon: _hintGenerating
                  ? SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.gold))
                  : const Icon(Icons.lightbulb_outline_rounded,
                      color: AppTheme.gold, size: 22),
            ),
          IconButton(
            onPressed: _newGame,
            icon: Icon(Icons.refresh_rounded,
                color: _modeColor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _modeBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: AppTheme.labelSmall.copyWith(color: color, fontSize: 9)),
      );

  String get _modeLabel {
    switch (widget.config.mode) {
      case GameMode.normal: return S.get('mode_normal');
      case GameMode.mystery: return S.get('mode_mystery');
      case GameMode.champion: return S.get('mode_champion');
    }
  }

  Widget _buildTimerRow(TimerEvent e) {
    final isWhiteTurn = _board.currentTurn == PieceColor.white;
    final isPlayerTurn = !widget.config.isOnePlayer ||
        _board.currentTurn == widget.config.playerColor;

    String blackLabel, whiteLabel;
    if (widget.config.isOnePlayer) {
      final isPlayerBlack = widget.config.playerColor == PieceColor.black;
      blackLabel = isPlayerBlack ? S.get('you') : S.get('bot');
      whiteLabel = isPlayerBlack ? S.get('bot') : S.get('you');
    } else {
      blackLabel = S.get('turn_black');
      whiteLabel = S.get('turn_white');
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Black side
            _timerSide(
              label: blackLabel,
              timer: _timerChip(e.blackFormatted, !isWhiteTurn, e.blackWarning, e.blackCritical, e.blackExpired),
              isActive: !isWhiteTurn,
              isBotThinking: _botThinking && isWhiteTurn, // bot just played, now white (so black was bot)
            ),
            // Center dot
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: _modeColor,
                boxShadow: [BoxShadow(color: _modeColor, blurRadius: 6)],
              ),
            ),
            // White side
            _timerSide(
              label: whiteLabel,
              timer: _timerChip(e.whiteFormatted, isWhiteTurn, e.whiteWarning, e.whiteCritical, e.whiteExpired),
              isActive: isWhiteTurn,
              isRight: true,
              isBotThinking: _botThinking && !isWhiteTurn,
            ),
          ],
        ),
      ),
      // Active turn banner below chips
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(top: 4, left: 24, right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isPlayerTurn && !_botThinking
              ? _modeColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isPlayerTurn && !_botThinking
                  ? _modeColor.withValues(alpha: 0.40)
                  : Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!_botThinking && isPlayerTurn) ...[
            Icon(Icons.arrow_forward_rounded, size: 12, color: _modeColor),
            const SizedBox(width: 5),
          ],
          Text(
            _botThinking
                ? S.get('bot_turn')
                : isPlayerTurn
                    ? S.get('your_turn')
                    : S.get('bot_turn'),
            style: AppTheme.labelSmall.copyWith(
                color: isPlayerTurn && !_botThinking ? _modeColor : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: isPlayerTurn && !_botThinking
                    ? FontWeight.w800
                    : FontWeight.w400),
          ),
        ]),
      ),
    ]);
  }

  Widget _timerSide({
    required String label,
    required Widget timer,
    required bool isActive,
    bool isRight = false,
    bool isBotThinking = false,
  }) {
    final labelWidget = Text(
      label.toUpperCase(),
      style: AppTheme.labelSmall.copyWith(
          color: isActive ? _modeColor : AppTheme.textMuted,
          fontSize: 9,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
          letterSpacing: 1),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isRight
          ? [timer, const SizedBox(width: 8), labelWidget]
          : [labelWidget, const SizedBox(width: 8), timer],
    );
  }

  Widget _timerChip(String time, bool active, bool warn, bool crit, bool exp) {
    final color = exp ? Colors.red : crit ? Colors.red : warn ? Colors.orange : _modeColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.2)),
      ),
      child: Text(time,
          style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1)),
    );
  }

  Widget _buildTurnRow() {
    final isPlayerTurn = !widget.config.isOnePlayer ||
        _board.currentTurn == widget.config.playerColor;
    final isWhiteTurn = _board.currentTurn == PieceColor.white;

    if (widget.config.isOnePlayer) {
      // 1-player: show YOUR TURN / BOT'S TURN clearly
      final (label, color, icon) = _botThinking
          ? ('⏳  ${S.get("bot_turn")}', AppTheme.textMuted, null)
          : isPlayerTurn
              ? (S.get('your_turn'), _modeColor, Icons.arrow_forward_rounded)
              : (S.get('bot_turn'), AppTheme.textMuted, null);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isPlayerTurn && !_botThinking
              ? _modeColor.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isPlayerTurn && !_botThinking
                  ? _modeColor.withValues(alpha: 0.5)
                  : Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: AppTheme.labelSmall.copyWith(
                  color: color,
                  fontSize: 12,
                  fontWeight: isPlayerTurn && !_botThinking
                      ? FontWeight.w800
                      : FontWeight.w500)),
        ]),
      );
    }

    // 2-player: show which side's turn
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _turnIndicator(S.get('turn_black'), !isWhiteTurn),
      const SizedBox(width: 20),
      Container(width: 1, height: 24, color: AppTheme.textMuted.withValues(alpha: 0.3)),
      const SizedBox(width: 20),
      _turnIndicator(S.get('turn_white'), isWhiteTurn),
    ]);
  }

  Widget _turnIndicator(String label, bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: active ? _modeColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active ? _modeColor : Colors.transparent),
      ),
      child: Text(label,
          style: AppTheme.labelSmall.copyWith(
              color: active ? _modeColor : AppTheme.textMuted, fontSize: 11)),
    );
  }

  Widget _buildBoard(PieceSkinDef skin, BoardSkinDef boardSkin) {
    return LayoutBuilder(builder: (ctx, box) {
      final size = box.maxWidth.clamp(260.0, 380.0);
      final sq = size / 8;
      return Container(
        width: size + 40,
        height: size + 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: _modeColor.withValues(alpha: 0.25), blurRadius: 28),
            const BoxShadow(color: Colors.black54, blurRadius: 16),
          ],
        ),
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: size + 40, height: size + 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _modeColor.withValues(alpha: 0.4), width: 1.5),
            ),
          ),
          // Rank labels
          Positioned(
            left: 5,
            child: SizedBox(
              width: 14, height: size,
              child: Column(children: List.generate(8, (i) => SizedBox(
                height: sq,
                child: Center(child: Text(
                    _isFlipped ? '${i + 1}' : '${8 - i}',
                    style: AppTheme.labelSmall.copyWith(
                        color: _modeColor.withValues(alpha: 0.6), fontSize: 8))),
              ))),
            ),
          ),
          // File labels
          Positioned(
            bottom: 5,
            child: SizedBox(
              width: size, height: 14,
              child: Row(children: List.generate(8, (i) => SizedBox(
                width: sq,
                child: Center(child: Text(
                    _isFlipped
                        ? String.fromCharCode('h'.codeUnitAt(0) - i)
                        : String.fromCharCode('a'.codeUnitAt(0) + i),
                    style: AppTheme.labelSmall.copyWith(
                        color: _modeColor.withValues(alpha: 0.6), fontSize: 8))),
              ))),
            ),
          ),
          // Grid
          SizedBox(
            width: size, height: size,
            child: Column(
              children: List.generate(8, (ri) {
                final rank = _isFlipped ? ri : 7 - ri;
                return Row(
                  children: List.generate(8, (fi) {
                    final file = _isFlipped ? 7 - fi : fi;
                    return _buildSquare(Position(file, rank), sq, skin, boardSkin);
                  }),
                );
              }),
            ),
          ),
        ]),
      );
    });
  }

  Widget _buildSquare(
      Position pos, double sq, PieceSkinDef skin, BoardSkinDef boardSkin) {
    final piece = _board.getPieceAt(pos);
    final isDark = (pos.file + pos.rank) % 2 == 1;
    final isSelected = _selectedPiece?.position.file == pos.file &&
        _selectedPiece?.position.rank == pos.rank;
    final isValid = _validMoves.any((m) => m.file == pos.file && m.rank == pos.rank);
    final isLast = _lastMoved?.file == pos.file && _lastMoved?.rank == pos.rank;
    final isHintFrom = _hintPiece?.position.file == pos.file &&
        _hintPiece?.position.rank == pos.rank;
    final isHintTo = _hintTarget?.file == pos.file && _hintTarget?.rank == pos.rank;

    Color sqColor;
    if (isSelected) {
      sqColor = _modeColor.withValues(alpha: 0.45);
    } else if (isHintFrom) {
      sqColor = AppTheme.gold.withValues(alpha: 0.35);
    } else if (isLast) {
      sqColor = _modeColor.withValues(alpha: 0.2);
    } else {
      sqColor = isDark ? boardSkin.darkSquare : boardSkin.lightSquare;
    }

    // Fog: hide squares outside visibility — always from human player's perspective
    final humanColor = widget.config.isOnePlayer
        ? widget.config.playerColor
        : _board.currentTurn;
    final fogHidden = _visMap != null &&
        !_visMap![pos.rank][pos.file] &&
        (piece == null || piece.color != humanColor);

    return GestureDetector(
      onTap: () => _onSquareTap(pos),
      child: Container(
        width: sq, height: sq,
        decoration: BoxDecoration(
          color: fogHidden ? const Color(0xFF050510) : sqColor,
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.15), width: 0.3),
        ),
        child: Stack(alignment: Alignment.center, children: [
          // Fog overlay
          if (fogHidden)
            Container(color: Colors.black.withValues(alpha: 0.85)),
          // Valid move dots
          if (isValid && piece == null)
            Container(
              width: sq * 0.3, height: sq * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _modeColor.withValues(alpha: 0.7),
                boxShadow: [BoxShadow(color: _modeColor, blurRadius: 6)],
              ),
            ),
          if (isValid && piece != null)
            Container(
              width: sq - 3, height: sq - 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _modeColor, width: 2.5),
                color: _modeColor.withValues(alpha: 0.15),
              ),
            ),
          // Hint target highlight (golden arrow-style overlay)
          if (isHintTo && piece == null)
            Container(
              width: sq * 0.38, height: sq * 0.38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withValues(alpha: 0.85),
                boxShadow: [BoxShadow(color: AppTheme.gold, blurRadius: 10, spreadRadius: 1)],
              ),
            ),
          if (isHintTo && piece != null)
            Container(
              width: sq - 2, height: sq - 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 3),
                color: AppTheme.gold.withValues(alpha: 0.18),
                boxShadow: [BoxShadow(color: AppTheme.gold, blurRadius: 10)],
              ),
            ),
          // Piece render
          if (piece != null && !fogHidden)
            _buildPiece(piece, skin, sq, isSelected, isValid),
        ]),
      ),
    );
  }

  Widget _buildPiece(Piece piece, PieceSkinDef skin, double sq,
      bool isSelected, bool isValid) {
    final faceDown = _isFaceDown(piece);

    if (faceDown && _modeManager.isBlindfoldActive) {
      return const SizedBox.shrink();
    }

    if (faceDown) {
      return AnimatedOpacity(
        opacity: _peekActive ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: sq * 0.82,
          height: sq * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF2A2A3A), Color(0xFF141422)],
            ),
            border: Border.all(
              color: piece.color == PieceColor.white
                  ? Colors.white.withValues(alpha: 0.4)
                  : AppTheme.neonPurple.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: piece.color == PieceColor.white
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.neonPurple.withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: sq * 0.4,
                fontWeight: FontWeight.w900,
                color: piece.color == PieceColor.white
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.neonPurple.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    return ChessPieceWidget(
      key: ValueKey(piece),
      piece: piece,
      skin: skin,
      size: sq,
      isSelected: isSelected,
      isValidTarget: isValid,
    );
  }

  Widget _buildBottom(GameState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          constraints: const BoxConstraints(minHeight: 28),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Align(alignment: Alignment.centerLeft, child: _buildCapturedList(_board.capturedWhitePieces))), // Black captured these
              Expanded(child: Align(alignment: Alignment.centerRight, child: _buildCapturedList(_board.capturedBlackPieces))), // White captured these
            ],
          ),
        ),

        Container(
          height: 28,
          margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true, // Show latest moves first on the right
              itemCount: _board.moveHistory.length,
              itemBuilder: (context, index) {
                // Reverse index because of reverse: true
                final realIndex = _board.moveHistory.length - 1 - index;
                final move = _board.moveHistory[realIndex];
                final isWhite = realIndex % 2 == 0;
                final moveStr = '${isWhite ? "${(realIndex~/2)+1}." : ""} ${move.toAlgebraic()}';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: Text(
                      moveStr,
                      style: AppTheme.labelSmall.copyWith(
                        color: isWhite ? Colors.white70 : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        if (state == GameState.check)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Text(S.get('check_alert'),
                  style: AppTheme.titleMedium.copyWith(
                      color: Colors.red, letterSpacing: 2, fontSize: 13)),
            ]),
          ),

      ]),
    );
  }

  Widget _buildCapturedList(List<Piece> pieces) {
    if (pieces.isEmpty) return const SizedBox.shrink();
    // Sort by value (simple sorting based on enum index)
    final sorted = List<Piece>.from(pieces)..sort((a, b) => a.actualType.index.compareTo(b.actualType.index));
    return Wrap(
      spacing: 2,
      children: sorted.map((p) => Text(
        p.currentType.symbol,
        style: TextStyle(
          color: p.color == PieceColor.white ? const Color(0xFFE8E8FF) : const Color(0xFF808090),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        )
      )).toList(),
    );
  }

  Widget _buildCheckBanner() {
    final playerInCheck = _board.currentTurn == widget.config.playerColor ||
        !widget.config.isOnePlayer;
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (ctx, v, child) => Transform.translate(
          offset: Offset(0, -60 * (1 - v)),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 18)
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                playerInCheck
                    ? S.get('check_warning')
                    : S.get('check_alert'),
                style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildGameOver(GameState state, bool timerExpired) {
    String title, subtitle;
    if (timerExpired) {
      final expiredColor = _timerEvent!.whiteExpired
          ? S.get('turn_white')
          : S.get('turn_black');
      title = '⏰';
      subtitle = '$expiredColor — ${S.get("time_expired")}';
    } else if (state == GameState.checkmate) {
      final winner = _board.currentTurn == PieceColor.white
          ? S.get('turn_black')
          : S.get('turn_white');
      title = '♛';
      subtitle = '$winner ${S.get("wins")}';
    } else {
      title = '🤝';
      subtitle = S.get('stalemate');
    }

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _modeColor, width: 2),
            boxShadow: [BoxShadow(
                color: _modeColor.withValues(alpha: 0.4), blurRadius: 28)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              timerExpired ? S.get('checkmate') : (state == GameState.checkmate
                  ? S.get('checkmate')
                  : S.get('stalemate')),
              style: AppTheme.displayMedium.copyWith(color: _modeColor),
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style: AppTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.textMuted),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text(S.get('menu'), style: AppTheme.bodyMedium),
              ),
              const SizedBox(width: 14),
              ElevatedButton(
                onPressed: _newGame,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _modeColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text(S.get('play_again'),
                    style: AppTheme.titleMedium.copyWith(
                        color: Colors.black, fontSize: 13)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
