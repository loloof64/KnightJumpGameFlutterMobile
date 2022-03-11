import 'dart:math';
import 'board_utils.dart';
import 'board_elements.dart';

const _PIECES_TYPES = ['p', 'n', 'b', 'r', 'q'];

String generateGame({bool playerHasWhite = true, int ennemiesCount = 10}) {
  var board = List.generate(8, (_) => List.generate(8, (_) => ''));

  final knightSquare = _generatePlayerKnightLocation(
      board: board, playerHasWhite: playerHasWhite);
  final pieceToAdd = playerHasWhite ? 'N' : 'n';
  board[knightSquare.rank.index][knightSquare.file.index] = pieceToAdd;

  var previousCell = knightSquare;

  for (var addedennemiesCount = 0;
      addedennemiesCount < ennemiesCount;
      addedennemiesCount++) {
    var nextEnemyCell = _generateEnemyLocation(
        previousCell: previousCell,
        playerKnightCell: knightSquare,
        board: board,
        playerHasWhite: playerHasWhite);
    var nextEnemy = _generateEnemy(playerHasWhite: playerHasWhite);
    board[nextEnemyCell.rank.index][nextEnemyCell.file.index] = nextEnemy;

    previousCell = nextEnemyCell;
  }

  return fenFromBoard(board: board, playerHasWhite: playerHasWhite);
}

String _generateEnemy({required bool playerHasWhite}) {
  final random = new Random();
  final pieceType = _PIECES_TYPES[random.nextInt(_PIECES_TYPES.length)];
  return playerHasWhite ? pieceType.toLowerCase() : pieceType.toUpperCase();
}

Cell _generatePlayerKnightLocation(
    {required bool playerHasWhite, required List<List<String>> board}) {
  final random = new Random();
  return Cell.fromSquareIndex(random.nextInt(64));
}

Cell _generateEnemyLocation(
    {required Cell previousCell,
    required Cell playerKnightCell,
    required List<List<String>> board,
    required bool playerHasWhite}) {
  final random = new Random();
  var isValidCell = false;

  Cell result;

  do {
    result = Cell.fromSquareIndex(random.nextInt(64));
    if (result == playerKnightCell) continue;
    if (board[result.rank.index][result.file.index].isNotEmpty) continue;
    final deltaX = (result.file.index - previousCell.file.index).abs();
    final deltaY = (result.rank.index - previousCell.rank.index).abs();
    isValidCell = (deltaX + deltaY == 3) && deltaX > 0 && deltaY > 0;
  } while (!isValidCell);

  return result;
}
