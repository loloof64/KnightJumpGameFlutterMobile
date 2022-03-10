import 'dart:math';

const _PIECES_TYPES = ['p', 'n', 'b', 'r', 'q', 'k'];

String generateGame({bool playerHasWhite = true, int enemiesCount = 10}) {
  var board = List.generate(8, (_) => List.generate(8, (_) => ''));

  final knightSquare = _generatePlayerKnightLocation(
      board: board, playerHasWhite: playerHasWhite);
  final pieceToAdd = playerHasWhite ? 'N' : 'n';
  board[knightSquare.rank.index][knightSquare.file.index] = pieceToAdd;

  var previousCell = knightSquare;

  for (var addedEnemiesCount = 0;
      addedEnemiesCount < enemiesCount;
      addedEnemiesCount++) {
    var nextEnemyCell = _generateEnemyLocation(
        previousCell: previousCell,
        playerKnightCell: knightSquare,
        board: board,
        playerHasWhite: playerHasWhite);
    var nextEnemy = _generateEnemy(playerHasWhite: playerHasWhite);
    board[nextEnemyCell.rank.index][nextEnemyCell.file.index] = nextEnemy;

    previousCell = nextEnemyCell;
  }

  return _fenFromBoard(board: board, playerHasWhite: playerHasWhite);
}

enum _File { file_a, file_b, file_c, file_d, file_e, file_f, file_g, file_h }

enum _Rank { rank_1, rank_2, rank_3, rank_4, rank_5, rank_6, rank_7, rank_8 }

class _Cell {
  final _File file;
  final _Rank rank;

  const _Cell({required this.file, required this.rank});
  _Cell.fromSquareIndex(int squareIndex)
      : this(
            file: _File.values[squareIndex % 8],
            rank: _Rank.values[squareIndex ~/ 8]);
  @override
  bool operator ==(Object other) {
    if (other is! _Cell) return false;
    return other.file == file && other.rank == rank;
  }

  @override
  int get hashCode => file.index + 10 * rank.index;
}

String _fenFromBoard(
    {required List<List<String>> board, required bool playerHasWhite}) {
  var result = '';
  for (var j = 0; j < 8; j++) {
    var holes = 0;
    for (var i = 0; i < 8; i++) {
      final currentElem = board[j][i];
      if (currentElem.isEmpty)
        holes++;
      else {
        result += '${holes}';
        holes = 0;
        result += currentElem;
      }
    }
    if (holes > 0) {
      result += '${holes}';
    }
    if (j < 7) {
      result += '/';
    }
  }

  result += ' ${playerHasWhite ? 'w' : 'b'} - - 0 1';
  return result;
}

_Cell _generatePlayerKnightLocation(
    {required bool playerHasWhite, required List<List<String>> board}) {
  final random = new Random();
  return _Cell.fromSquareIndex(random.nextInt(64));
}

_Cell _generateEnemyLocation(
    {required _Cell previousCell,
    required _Cell playerKnightCell,
    required List<List<String>> board,
    required bool playerHasWhite}) {
  final random = new Random();
  var isValidCell = false;

  _Cell result;

  do {
    result = _Cell.fromSquareIndex(random.nextInt(64));
    if (result == playerKnightCell) continue;
    if (board[result.rank.index][result.file.index].isNotEmpty) continue;
    final deltaX = (result.file.index - previousCell.file.index).abs();
    final deltaY = (result.rank.index - previousCell.rank.index).abs();
    isValidCell = (deltaX + deltaY == 3) && deltaX > 0 && deltaY > 0;
  } while (!isValidCell);

  return result;
}

String _generateEnemy({required bool playerHasWhite}) {
  final random = new Random();
  final pieceType = _PIECES_TYPES[random.nextInt(_PIECES_TYPES.length)];
  return playerHasWhite ? pieceType.toLowerCase() : pieceType.toUpperCase();
}
