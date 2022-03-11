/*
    Knight Jump Game - Try to eat all ennemies with your knight on the 
    chess board.
    Copyright (C) 2022 Laurent Bernabe <laurent.bernabe@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
import 'package:flutter/material.dart';
import 'logic/board_utils.dart';
import 'logic/constants.dart';
import 'logic/board_elements.dart';
import 'package:chess/chess.dart' as chesslib;
import 'components/dialog_button.dart';
import 'logic/game_generator.dart';
import 'package:simple_chess_board/simple_chess_board.dart';
import 'package:flutter_i18n/loaders/decoders/yaml_decode_strategy.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'logic/win_loss_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => FlutterI18n.translate(context, 'app.title'),
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: 'assets/i18n',
            useCountryCode: false,
            fallbackFile: 'en',
            decodeStrategies: [YamlDecodeStrategy()],
          ),
          missingTranslationHandler: (key, locale) {
            Logger().w(
                "--- Missing Key: $key, languageCode: ${locale?.languageCode}");
          },
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _blackAtBottom = false;
  var _whitePlayerType = PlayerType.human;
  var _blackPlayerType = PlayerType.computer;
  var _fen = EMPTY_BOARD;
  var _playerHasWhite = true;
  var _ennemiesCount = MIN_ENEMIES_COUNT;

  void startNewGame() {
    if (_fen == EMPTY_BOARD)
      doStartNewGame();
    else {
      showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: I18nText('game.exit_current_game_title'),
              content: I18nText('game.exit_current_game_msg'),
              actions: [
                DialogActionButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    doStartNewGame();
                  },
                  textContent: I18nText('button.ok'),
                  backgroundColor: Colors.greenAccent,
                  textColor: Colors.white,
                ),
                DialogActionButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  textContent: I18nText('button.cancel'),
                  backgroundColor: Colors.redAccent,
                  textColor: Colors.white,
                ),
              ],
            );
          });
    }
  }

  void doStartNewGame() {
    showDialog<int?>(
        context: context,
        builder: (ctx) {
          return _EnnemiesCountSelectionDialog(
              minValue: MIN_ENEMIES_COUNT,
              maxValue: MAX_ENEMIES_COUNT,
              startValue: _ennemiesCount,
              onValidated: (newCount) {
                setState(() {
                  _ennemiesCount = newCount;
                  final newFen = generateGame(
                      playerHasWhite: true, ennemiesCount: _ennemiesCount);
                  _fen = newFen;
                });
              });
        });
  }

  void validateMove({required ShortMove move}) {
    final playerSide = chesslib.Color.WHITE;
    final ennemySide = chesslib.Color.BLACK;
    final chess = chesslib.Chess.fromFEN(_fen);

    final fromPiece = chess.get(move.from);
    final toPiece = chess.get(move.to);
    if (fromPiece == null) return;
    if (fromPiece.type != chesslib.PieceType.KNIGHT ||
        fromPiece.color != playerSide) return;
    if (toPiece == null) return;
    if (toPiece.color != ennemySide) return;

    final fromCell = Cell.fromAlgebraic(algebraic: move.from);
    final toCell = Cell.fromAlgebraic(algebraic: move.to);
    final deltaX = (fromCell.file.index - toCell.file.index).abs();
    final deltaY = (fromCell.rank.index - toCell.rank.index).abs();
    final moveSuccess = (deltaX + deltaY) == 3 && deltaX > 0 && deltaY > 0;

    if (moveSuccess) {
      _movePlayerKnight(playerKnightCell: fromCell, targetCell: toCell);
      checkForGameEnded();
    }
  }

  void checkForGameEnded() {
    final gameLost =
        isGameLost(position: _fen, playerHasWhite: _playerHasWhite);
    if (gameLost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [I18nText('game.lost')],
          ),
        ),
      );
      return;
    }
    final gameWon = isGameWon(position: _fen, playerHasWhite: _playerHasWhite);
    if (gameWon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [I18nText('game.won')],
          ),
        ),
      );
    }
  }

  void _movePlayerKnight({
    required Cell playerKnightCell,
    required Cell targetCell,
  }) {
    var newFen = _fen;
    final board = positionToBoardArray(position: newFen);

    board[7 - playerKnightCell.rank.index][playerKnightCell.file.index] = '';
    board[7 - targetCell.rank.index][targetCell.file.index] =
        _playerHasWhite ? 'N' : 'n';
    newFen = fenFromBoard(board: board, playerHasWhite: _playerHasWhite);

    setState(() {
      _fen = newFen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final boardOrientation =
        _blackAtBottom ? BoardColor.black : BoardColor.white;
    final isPortraitLayout =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: AppBar(
        title: I18nText('app.title'),
        actions: [
          IconButton(
            onPressed: startNewGame,
            icon: Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: Center(
        child: isPortraitLayout
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SimpleChessBoard(
                    fen: _fen,
                    onMove: validateMove,
                    orientation: boardOrientation,
                    whitePlayerType: _whitePlayerType,
                    blackPlayerType: _blackPlayerType,
                    showCoordinatesZone: false,
                    onPromote: () async {
                      return null;
                    },
                    engineThinking: false,
                  )
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SimpleChessBoard(
                    fen: _fen,
                    onMove: validateMove,
                    orientation: boardOrientation,
                    whitePlayerType: _whitePlayerType,
                    blackPlayerType: _blackPlayerType,
                    showCoordinatesZone: false,
                    onPromote: () async {
                      return null;
                    },
                    engineThinking: false,
                  )
                ],
              ),
      ),
    );
  }
}

class _EnnemiesCountSelectionDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int startValue;
  final void Function(int selectedCount) onValidated;
  const _EnnemiesCountSelectionDialog({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.startValue,
    required this.onValidated,
  }) : super(key: key);

  @override
  State<_EnnemiesCountSelectionDialog> createState() =>
      _EnnemiesCountSelectionDialogState();
}

class _EnnemiesCountSelectionDialogState
    extends State<_EnnemiesCountSelectionDialog> {
  var _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.startValue;
  }

  @override
  Widget build(BuildContext context) {
    var valuesChildren = <DropdownMenuItem<int>>[];
    for (var value = widget.minValue; value <= widget.maxValue; value++) {
      valuesChildren.add(
        DropdownMenuItem(
          child: Text("$value"),
          value: value,
        ),
      );
    }
    return AlertDialog(
      title: I18nText('game.new_game_title'),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
              value: _count,
              items: valuesChildren,
              onChanged: (newValue) {
                if (newValue != null)
                  setState(() {
                    _count = newValue;
                  });
              }),
        ],
      ),
      actions: [
        DialogActionButton(
          onPressed: () {
            widget.onValidated(_count);
            Navigator.of(context).pop();
          },
          textContent: I18nText('button.ok'),
          backgroundColor: Colors.greenAccent,
          textColor: Colors.white,
        ),
        DialogActionButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          textContent: I18nText('button.cancel'),
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
        ),
      ],
    );
  }
}
