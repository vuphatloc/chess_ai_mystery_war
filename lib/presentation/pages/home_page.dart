import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/board.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/game_rules_engine.dart';
import '../../domain/services/shuffle_service.dart';
import '../../domain/value_objects/position.dart';
import '../../domain/value_objects/piece_color.dart';
import '../../domain/value_objects/piece_type.dart';
import '../../domain/value_objects/game_state.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Board _board;
  Piece? _selectedPiece;
  List<Position> _validMoves = [];

  @override
  void initState() {
    super.initState();
    _board = Board.initial();
    _board = ShuffleService.shuffleBoard(_board);
  }

  void _onSquareTap(Position position) {
    final piece = _board.getPieceAt(position);

    if (_selectedPiece != null) {
      // Try to move selected piece
      if (_validMoves.any(
          (move) => move.file == position.file && move.rank == position.rank)) {
        setState(() {
          _board = _board.movePiece(_selectedPiece!, position);
          _selectedPiece = null;
          _validMoves.clear();
        });
      } else if (piece != null && piece.color == _board.currentTurn) {
        // Select new piece
        setState(() {
          _selectedPiece = piece;
          _validMoves = GameRulesEngine.getValidMoves(_board, piece);
        });
      } else {
        // Deselect
        setState(() {
          _selectedPiece = null;
          _validMoves = [];
        });
      }
    } else if (piece != null && piece.color == _board.currentTurn) {
      // Select piece
      setState(() {
        _selectedPiece = piece;
        _validMoves = GameRulesEngine.getValidMoves(_board, piece);
      });
    }
  }

  void _newGame() {
    setState(() {
      _board = Board.initial();
      _board = ShuffleService.shuffleBoard(_board);
      _selectedPiece = null;
      _validMoves = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess AI: Mystery War'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _newGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Turn: ${_board.currentTurn.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _buildChessBoard(),
            const SizedBox(height: 20),
            _buildGameInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildChessBoard() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int rank = 7; rank >= 0; rank--)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${rank + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: 4),
                for (int file = 0; file < 8; file++)
                  _buildSquare(Position(file, rank)),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 20),
              for (int file = 0; file < 8; file++)
                SizedBox(
                  width: 40,
                  child: Text(
                    String.fromCharCode('a'.codeUnitAt(0) + file),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquare(Position position) {
    final piece = _board.getPieceAt(position);
    final isSelected = _selectedPiece != null &&
        _selectedPiece!.position.file == position.file &&
        _selectedPiece!.position.rank == position.rank;
    final isValidMove = _validMoves.any(
        (move) => move.file == position.file && move.rank == position.rank);
    final isDark = (position.file + position.rank) % 2 == 1;

    return GestureDetector(
      onTap: () => _onSquareTap(position),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : isValidMove
                  ? Colors.green
                  : isDark
                      ? Colors.brown[700]
                      : Colors.brown[300],
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: piece != null
            ? Center(
                child: Text(
                  _getPieceSymbol(piece),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: piece.color == PieceColor.white
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _getPieceSymbol(Piece piece) {
    final type = piece.currentType;
    switch (type) {
      case PieceType.pawn:
        return '♟';
      case PieceType.rook:
        return '♜';
      case PieceType.knight:
        return '♞';
      case PieceType.bishop:
        return '♝';
      case PieceType.queen:
        return '♛';
      case PieceType.king:
        return '♚';
    }
  }

  Widget _buildGameInfo() {
    final gameState = GameRulesEngine.getGameState(_board);

    return Column(
      children: [
        Text(
          'Game State: ${gameState.description}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (_selectedPiece != null)
          Text(
            'Selected: ${_selectedPiece!.currentType.name} at ${_selectedPiece!.position.toAlgebraic()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (_validMoves.isNotEmpty)
          Text(
            'Valid moves: ${_validMoves.map((p) => p.toAlgebraic()).join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
