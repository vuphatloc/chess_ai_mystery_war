import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../presentation/widgets/particle_background.dart';
import 'game_mode_selector_screen.dart';

import '../../domain/entities/board.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/game_rules_engine.dart';
import '../../domain/services/shuffle_service.dart';
import '../../domain/value_objects/position.dart';
import '../../domain/value_objects/piece_color.dart';
import '../../domain/value_objects/piece_type.dart';
import '../../domain/value_objects/game_state.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Board _board;
  Piece? _selectedPiece;
  List<Position> _validMoves = [];
  late AnimationController _moveAnim;
  Position? _lastMoved;

  @override
  void initState() {
    super.initState();
    _newGame();
    _moveAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _moveAnim.dispose();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _board = Board.initial();
      if (widget.mode == GameMode.mystery) {
        _board = ShuffleService.shuffleBoard(_board);
      }
      _selectedPiece = null;
      _validMoves = [];
      _lastMoved = null;
    });
  }

  void _onSquareTap(Position position) {
    final piece = _board.getPieceAt(position);

    if (_selectedPiece != null) {
      if (_validMoves.any((m) => m.file == position.file && m.rank == position.rank)) {
        setState(() {
          _board = _board.movePiece(_selectedPiece!, position);
          _lastMoved = position;
          _selectedPiece = null;
          _validMoves.clear();
        });
        _moveAnim.forward(from: 0);
      } else if (piece != null && piece.color == _board.currentTurn) {
        setState(() {
          _selectedPiece = piece;
          _validMoves = GameRulesEngine.getValidMoves(_board, piece);
        });
      } else {
        setState(() {
          _selectedPiece = null;
          _validMoves = [];
        });
      }
    } else if (piece != null && piece.color == _board.currentTurn) {
      setState(() {
        _selectedPiece = piece;
        _validMoves = GameRulesEngine.getValidMoves(_board, piece);
      });
    }
  }

  Color get _modeColor {
    switch (widget.mode) {
      case GameMode.normal: return AppTheme.neonCyan;
      case GameMode.mystery: return AppTheme.neonPurple;
      case GameMode.champion: return AppTheme.gold;
    }
  }

  String get _modeLabel {
    switch (widget.mode) {
      case GameMode.normal: return 'NORMAL';
      case GameMode.mystery: return 'MYSTERY';
      case GameMode.champion: return 'CHAMPION';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = GameRulesEngine.getGameState(_board);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient)),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, gameState),
                const SizedBox(height: 16),
                _buildTurnIndicator(),
                const SizedBox(height: 16),
                Expanded(child: Center(child: _buildBoard())),
                _buildBottomPanel(gameState),
              ],
            ),
          ),
          if (gameState == GameState.checkmate || gameState == GameState.stalemate)
            _buildGameOverOverlay(gameState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textSecondary, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHESS AI', style: AppTheme.labelSmall),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _modeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _modeColor.withOpacity(0.4)),
                    ),
                    child: Text(_modeLabel,
                        style: AppTheme.labelSmall.copyWith(color: _modeColor, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _newGame,
            icon: Icon(Icons.refresh_rounded, color: _modeColor.withOpacity(0.8)),
            tooltip: 'New Game',
          ),
          IconButton(
            onPressed: _showSettingsQuick,
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showSettingsQuick() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            _OptionTile(icon: Icons.refresh_rounded, label: 'New Game', color: _modeColor, onTap: () { Navigator.pop(context); _newGame(); }),
            _OptionTile(icon: Icons.exit_to_app_rounded, label: 'Quit to Menu', color: AppTheme.textSecondary, onTap: () { Navigator.pop(context); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIndicator() {
    final isWhite = _board.currentTurn == PieceColor.white;
    final turnColor = isWhite ? Colors.white : AppTheme.textMuted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPlayerIndicator('BLACK', _board.currentTurn == PieceColor.black),
        const SizedBox(width: 24),
        Container(
          width: 1,
          height: 28,
          color: AppTheme.textMuted.withOpacity(0.3),
        ),
        const SizedBox(width: 24),
        _buildPlayerIndicator('WHITE', _board.currentTurn == PieceColor.white),
      ],
    );
  }

  Widget _buildPlayerIndicator(String label, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? _modeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _modeColor : Colors.transparent,
          width: 1,
        ),
        boxShadow: isActive ? [BoxShadow(color: _modeColor.withOpacity(0.3), blurRadius: 10)] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _modeColor,
                boxShadow: [BoxShadow(color: _modeColor, blurRadius: 4)]),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: AppTheme.labelSmall.copyWith(
                color: isActive ? _modeColor : AppTheme.textMuted,
                fontSize: 11,
              )),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(builder: (context, constraints) {
      final boardSize = constraints.maxWidth.clamp(280.0, 420.0);
      final squareSize = boardSize / 8;

      return Container(
        width: boardSize + 40,
        height: boardSize + 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: _modeColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 2),
            const BoxShadow(color: Colors.black54, blurRadius: 20),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Board border/frame
            Container(
              width: boardSize + 40,
              height: boardSize + 40,
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _modeColor.withOpacity(0.3), width: 1),
              ),
            ),
            // Rank labels
            Positioned(
              left: 8,
              child: SizedBox(
                width: 16,
                height: boardSize,
                child: Column(
                  children: List.generate(8, (i) => SizedBox(
                    height: squareSize,
                    child: Center(
                      child: Text('${8 - i}',
                          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted, fontSize: 10)),
                    ),
                  )),
                ),
              ),
            ),
            // File labels
            Positioned(
              bottom: 8,
              child: SizedBox(
                width: boardSize,
                height: 16,
                child: Row(
                  children: List.generate(8, (i) => SizedBox(
                    width: squareSize,
                    child: Center(
                      child: Text(String.fromCharCode('a'.codeUnitAt(0) + i),
                          style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted, fontSize: 10)),
                    ),
                  )),
                ),
              ),
            ),
            // Chess squares
            SizedBox(
              width: boardSize,
              height: boardSize,
              child: Column(
                children: List.generate(8, (rankIdx) {
                  final rank = 7 - rankIdx;
                  return Row(
                    children: List.generate(8, (file) {
                      return _buildSquare(Position(file, rank), squareSize);
                    }),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSquare(Position position, double size) {
    final piece = _board.getPieceAt(position);
    final isSelected = _selectedPiece != null &&
        _selectedPiece!.position.file == position.file &&
        _selectedPiece!.position.rank == position.rank;
    final isValidMove = _validMoves.any((m) => m.file == position.file && m.rank == position.rank);
    final isLastMoved = _lastMoved != null &&
        _lastMoved!.file == position.file && _lastMoved!.rank == position.rank;
    final isDark = (position.file + position.rank) % 2 == 1;

    Color squareColor;
    if (isSelected) {
      squareColor = _modeColor.withOpacity(0.4);
    } else if (isValidMove) {
      squareColor = _modeColor.withOpacity(0.2);
    } else if (isLastMoved) {
      squareColor = _modeColor.withOpacity(0.15);
    } else {
      squareColor = isDark ? AppTheme.boardDark : AppTheme.boardLight;
    }

    return GestureDetector(
      onTap: () => _onSquareTap(position),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: squareColor,
          border: isSelected
              ? Border.all(color: _modeColor, width: 2)
              : Border.all(color: Colors.black12, width: 0.5),
          boxShadow: isSelected
              ? [BoxShadow(color: _modeColor.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Valid move indicator dot (when no piece)
            if (isValidMove && piece == null)
              Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _modeColor.withOpacity(0.7),
                  boxShadow: [BoxShadow(color: _modeColor, blurRadius: 6)],
                ),
              ),
            // Valid move indicator ring (when piece to capture)
            if (isValidMove && piece != null)
              Container(
                width: size - 4,
                height: size - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _modeColor, width: 3),
                ),
              ),
            // Piece
            if (piece != null)
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getPieceSymbol(piece),
                  style: TextStyle(
                    fontSize: size * 0.68,
                    color: piece.color == PieceColor.white
                        ? AppTheme.textPrimary
                        : const Color(0xFF1A1A2E),
                    shadows: [
                      if (piece.color == PieceColor.white)
                        Shadow(color: _modeColor.withOpacity(0.4), blurRadius: 8),
                      const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 2)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPieceSymbol(Piece piece) {
    switch (piece.currentType) {
      case PieceType.pawn:   return piece.color == PieceColor.white ? '♙' : '♟';
      case PieceType.rook:   return piece.color == PieceColor.white ? '♖' : '♜';
      case PieceType.knight: return piece.color == PieceColor.white ? '♘' : '♞';
      case PieceType.bishop: return piece.color == PieceColor.white ? '♗' : '♝';
      case PieceType.queen:  return piece.color == PieceColor.white ? '♕' : '♛';
      case PieceType.king:   return piece.color == PieceColor.white ? '♔' : '♚';
    }
  }

  Widget _buildBottomPanel(GameState gameState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gameState == GameState.check)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('CHECK!',
                      style: AppTheme.titleMedium.copyWith(color: Colors.red, letterSpacing: 2)),
                ],
              ),
            ),
          if (_selectedPiece != null)
            Text(
              '${_selectedPiece!.currentType.name.toUpperCase()} · ${_validMoves.length} moves',
              style: AppTheme.labelSmall.copyWith(color: _modeColor),
            ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(GameState gameState) {
    final isCheckmate = gameState == GameState.checkmate;
    final winner = isCheckmate
        ? (_board.currentTurn == PieceColor.white ? 'BLACK' : 'WHITE')
        : null;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _modeColor, width: 2),
            boxShadow: [BoxShadow(color: _modeColor.withOpacity(0.4), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isCheckmate ? '♛' : '🤝', style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text(
                isCheckmate ? 'CHECKMATE!' : 'STALEMATE',
                style: AppTheme.displayMedium.copyWith(color: _modeColor),
              ),
              if (winner != null) ...[
                const SizedBox(height: 8),
                Text('$winner WINS', style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary)),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.textMuted),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Menu', style: AppTheme.bodyMedium),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _newGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _modeColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Play Again', style: AppTheme.titleMedium.copyWith(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary)),
      onTap: onTap,
    );
  }
}
