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
  bool _peekActive = false;
  Timer? _peekTimer;

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
    // Sync audio settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(userSettingsProvider);
      _audio.setMusicEnabled(s.musicEnabled);
      _audio.setSfxEnabled(s.sfxEnabled);
      _audio.playBgmForMode(widget.config);
    });
    _newGame();
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    _timerService?.dispose();
    _peekTimer?.cancel();
    _audio.stopBgm();
    super.dispose();
  }

  void _newGame() {
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
      _updateVisibility();
    });
    _timerService?.reset(isWhiteTurn: true);
    if (widget.config.hasTimeLimit) {
      _timerService?.start(isWhiteTurn: true);
    }
    _blindfoldFaded = false;
    _audio.playBgmForMode(widget.config);
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
    _visMap = _modeManager.getVisibleSquares(_board, _board.currentTurn);
  }

  bool _isVisible(Piece piece) {
    if (_visMap == null) return true;
    return _modeManager.isPieceVisible(_board, piece, _board.currentTurn, _visMap!);
  }

  bool _isFaceDown(Piece piece) {
    if (_peekActive) return false;
    return _modeManager.isPieceFaceDown(piece, _board.currentTurn, _totalMoves);
  }

  void _onSquareTap(Position pos) {
    if (_botThinking) return;
    final isMyTurn = !widget.config.isOnePlayer ||
        _board.currentTurn == PieceColor.white;
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

    if (isCapture && targetPiece != null) {
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
      _updateVisibility();
    });

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
    if (gameState == GameState.checkmate) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_board.currentTurn == PieceColor.white) {
          // Bot won (black delivered checkmate, now white's turn = white is in checkmate)
          _audio.playLose();
        } else {
          _audio.playWin();
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
    if (_board.currentTurn != PieceColor.black) return;
    setState(() => _botThinking = true);
    _botService!.getBestMove(_board, PieceColor.black).then((move) {
      if (!mounted || move == null) return;
      _doMove(move.piece, move.target);
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
    final gameState = GameRulesEngine.getGameState(_board);
    final timerExpired = _timerEvent?.anyExpired ?? false;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient)),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                if (widget.config.hasTimeLimit && _timerEvent != null)
                  _buildTimerRow(_timerEvent!)
                else
                  _buildTurnRow(),
                const SizedBox(height: 8),
                Expanded(child: Center(child: _buildBoard(skin, boardSkin))),
                _buildBottom(gameState),
              ],
            ),
          ),
          if (_botThinking)
            Positioned(
              bottom: 80, left: 0, right: 0,
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
          if (gameState == GameState.checkmate ||
              gameState == GameState.stalemate ||
              timerExpired)
            _buildGameOver(gameState, timerExpired),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
    final isWhite = _board.currentTurn == PieceColor.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            _timerChip(e.blackFormatted, !isWhite, e.blackWarning, e.blackCritical, e.blackExpired),
            if (!isWhite) const SizedBox(width: 8),
            if (!isWhite) const Icon(Icons.arrow_left, color: AppTheme.neonCyan),
          ]),
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: _modeColor,
              boxShadow: [BoxShadow(color: _modeColor, blurRadius: 6)],
            ),
          ),
          Row(children: [
            if (isWhite) const Icon(Icons.arrow_right, color: AppTheme.neonCyan),
            if (isWhite) const SizedBox(width: 8),
            _timerChip(e.whiteFormatted, isWhite, e.whiteWarning, e.whiteCritical, e.whiteExpired),
          ]),
        ],
      ),
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
    final isWhite = _board.currentTurn == PieceColor.white;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _turnIndicator(S.get('turn_black'), !isWhite),
      const SizedBox(width: 20),
      Container(width: 1, height: 24, color: AppTheme.textMuted.withValues(alpha: 0.3)),
      const SizedBox(width: 20),
      _turnIndicator(S.get('turn_white'), isWhite),
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
                child: Center(child: Text('${8 - i}',
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
                    String.fromCharCode('a'.codeUnitAt(0) + i),
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
                final rank = 7 - ri;
                return Row(
                  children: List.generate(8, (file) =>
                      _buildSquare(Position(file, rank), sq, skin, boardSkin)),
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

    Color sqColor;
    if (isSelected) {
      sqColor = _modeColor.withValues(alpha: 0.45);
    } else if (isLast) {
      sqColor = _modeColor.withValues(alpha: 0.2);
    } else {
      sqColor = isDark ? boardSkin.darkSquare : boardSkin.lightSquare;
    }

    // Fog: hide squares outside visibility
    final fogHidden = _visMap != null &&
        !_visMap![pos.rank][pos.file] &&
        (piece == null || piece.color != _board.currentTurn);

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

    if (faceDown) {
      // Render as face-down token
      return AnimatedOpacity(
        opacity: _peekActive ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: sq * 0.82, height: sq * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF2A2A3A),
              const Color(0xFF141422),
            ]),
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
            child: Text('?',
                style: TextStyle(
                    fontSize: sq * 0.4,
                    fontWeight: FontWeight.w900,
                    color: piece.color == PieceColor.white
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.neonPurple.withValues(alpha: 0.6))),
          ),
        ),
      );
    }

    return ChessPieceWidget(
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
        if (_board.capturedWhitePieces.isNotEmpty || _board.capturedBlackPieces.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCapturedList(_board.capturedWhitePieces), // Black captured these
                _buildCapturedList(_board.capturedBlackPieces), // White captured these
              ],
            ),
          ),

        if (_board.moveHistory.isNotEmpty)
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
        if (_selectedPiece != null)
          Text(
            '${_validMoves.length} ${S.get("moves")}',
            style: AppTheme.labelSmall.copyWith(color: _modeColor),
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
