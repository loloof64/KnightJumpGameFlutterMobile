import 'board_elements.dart';
import 'board_utils.dart';

bool isGameLost({required String position, required bool playerHasWhite}) {
  final board = positionToBoardArray(position: position);
  final playerKnightCell =
      _findPlayerKnightCell(board: board, playerHasWhite: playerHasWhite);
  final trappableEnemiesCount = _findTrappableEnemiesCount(
    board: board,
    playerHasWhite: playerHasWhite,
    playerKnightCell: playerKnightCell,
  );
  final remainingEnemiesCount = _findRemainingEnemiesCount(
    board: board,
    playerHasWhite: playerHasWhite,
  );
  return remainingEnemiesCount > 0 && trappableEnemiesCount == 0;
}

bool isGameWon({required String position, required bool playerHasWhite}) {
  final board = positionToBoardArray(position: position);
  final remainingEnemiesCount = _findRemainingEnemiesCount(
    board: board,
    playerHasWhite: playerHasWhite,
  );
  return remainingEnemiesCount == 0;
}

Cell _findPlayerKnightCell(
    {required bool playerHasWhite, required List<List<String>> board}) {
  final playerKnightFen = playerHasWhite ? 'N' : 'n';
  int playerKnightCounts = 0;
  late Cell playerKnightLocation;

  for (var rank = 0; rank < 8; rank++) {
    for (var file = 0; file < 8; file++) {
      if (board[rank][file] == playerKnightFen) {
        playerKnightLocation = Cell.fromSquareIndex(file + 8 * rank);
        playerKnightCounts++;
      }
    }
  }
  if (playerKnightCounts != 1)
    throw "Board has not exactly one player knight !";

  return playerKnightLocation;
}

int _findTrappableEnemiesCount(
    {required List<List<String>> board,
    required bool playerHasWhite,
    required Cell playerKnightCell}) {
  var result = 0;

  for (var rank = 0; rank < 8; rank++) {
    for (var file = 0; file < 8; file++) {
      final currentCell = Cell.fromSquareIndex(file + 8 * rank);
      if (_isEnemy(
              elementFen: board[rank][file], playerHasWhite: playerHasWhite) &&
          _isTrappable(
              cellToTest: currentCell, playerKnightCell: playerKnightCell)) {
        result++;
      }
    }
  }

  return result;
}

int _findRemainingEnemiesCount(
    {required List<List<String>> board, required bool playerHasWhite}) {
  var result = 0;

  for (var rank = 0; rank < 8; rank++) {
    for (var file = 0; file < 8; file++) {
      if (_isEnemy(
          elementFen: board[rank][file], playerHasWhite: playerHasWhite)) {
        result++;
      }
    }
  }

  return result;
}

bool _isEnemy({required String elementFen, required bool playerHasWhite}) {
  if (elementFen.isEmpty) return false;
  return playerHasWhite
      ? elementFen[0].toLowerCase() == elementFen[0]
      : elementFen[0].toUpperCase() == elementFen[0];
}

bool _isTrappable({required Cell cellToTest, required Cell playerKnightCell}) {
  final deltaX = (cellToTest.file.index - playerKnightCell.file.index).abs();
  final deltaY = (cellToTest.rank.index - playerKnightCell.rank.index).abs();

  return (deltaX + deltaY) == 3 && deltaX > 0 && deltaY > 0;
}
