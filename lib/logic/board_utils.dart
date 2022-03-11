String fenFromBoard(
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

List<List<String>> positionToBoardArray({required String position}) {
  var board = List.generate(8, (_) => List.generate(8, (_) => ''));

  final boardLines = position.split(' ')[0].split('/');
  for (var lineIndex = 0; lineIndex < boardLines.length; lineIndex++) {
    final lineElements = boardLines[lineIndex].split('');
    var column = 0;

    lineElements.forEach((element) {
      final digit = int.tryParse(element);
      if (digit != null) {
        column += digit;
      } else {
        board[lineIndex][column] = element;
        column++;
      }
    });
  }

  return board;
}
