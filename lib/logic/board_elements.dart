enum File { file_a, file_b, file_c, file_d, file_e, file_f, file_g, file_h }

enum Rank { rank_1, rank_2, rank_3, rank_4, rank_5, rank_6, rank_7, rank_8 }

class Cell {
  final File file;
  final Rank rank;

  const Cell({required this.file, required this.rank});
  Cell.fromSquareIndex(int squareIndex)
      : this(
            file: File.values[squareIndex % 8],
            rank: Rank.values[squareIndex ~/ 8]);

  Cell.fromAlgebraic({required String algebraic})
      : this(
          file: File.values[algebraic.codeUnitAt(0) - 'a'.codeUnitAt(0)],
          rank: Rank.values[algebraic.codeUnitAt(1) - '1'.codeUnitAt(0)],
        );

  @override
  bool operator ==(Object other) {
    if (other is! Cell) return false;
    return other.file == file && other.rank == rank;
  }

  @override
  int get hashCode => file.index + 10 * rank.index;

  @override
  String toString() {
    return "${String.fromCharCode('a'.codeUnitAt(0) + file.index)}"
        "${String.fromCharCode('1'.codeUnitAt(0) + rank.index)}";
  }
}
