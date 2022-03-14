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
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_chess_board/models/board_arrow.dart';
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
        primarySwatch: Colors.green,
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
  var _whitePlayerType = PlayerType.computer;
  var _blackPlayerType = PlayerType.computer;
  var _fen = EMPTY_BOARD;
  var _playerHasWhite = true;
  var _ennemiesCount = MIN_ENEMIES_COUNT;
  var _gameEnded = false;
  BoardArrow? _lastMoveArrow = null;
  var _solution = <SolutionStep>[];
  var _startPosition = EMPTY_BOARD;

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
                var random = new Random();
                var playerHasWhite = random.nextBool();
                setState(() {
                  _ennemiesCount = newCount;
                  _playerHasWhite = playerHasWhite;
                  _whitePlayerType =
                      _playerHasWhite ? PlayerType.human : PlayerType.computer;
                  _blackPlayerType =
                      _playerHasWhite ? PlayerType.computer : PlayerType.human;
                  final newGame = generateGame(
                      playerHasWhite: _playerHasWhite,
                      ennemiesCount: _ennemiesCount);
                  _gameEnded = false;
                  _fen = newGame.initialPosition;
                  _startPosition = newGame.initialPosition;
                  _lastMoveArrow = null;
                  _solution = newGame.solution;
                });
              });
        });
  }

  void validateMove({required ShortMove move}) {
    final playerSide =
        _playerHasWhite ? chesslib.Color.WHITE : chesslib.Color.BLACK;
    final ennemySide =
        _playerHasWhite ? chesslib.Color.BLACK : chesslib.Color.WHITE;
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
      setState(() {
        _whitePlayerType = PlayerType.computer;
        _blackPlayerType = PlayerType.computer;
        _fen = _startPosition;
        _gameEnded = true;
      });
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
      setState(() {
        _whitePlayerType = PlayerType.computer;
        _blackPlayerType = PlayerType.computer;
        _fen = _startPosition;
        _gameEnded = true;
      });
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

  void _selectPreviousStep(
      {required SolutionStep step, required SolutionStep? previousStep}) {
    var newFen = _fen;
    final board = positionToBoardArray(position: newFen);

    board[step.from.rank.index][step.from.file.index] =
        _playerHasWhite ? 'N' : 'n';
    board[step.to.rank.index][step.to.file.index] = step.eatenEnnemy;
    newFen = fenFromBoard(board: board, playerHasWhite: _playerHasWhite);

    setState(() {
      _fen = newFen;
      _lastMoveArrow = previousStep != null
          ? BoardArrow(
              from: Cell.fromSquareIndex(previousStep.from.file.index +
                      8 * (7 - previousStep.from.rank.index))
                  .toString(),
              to: Cell.fromSquareIndex(previousStep.to.file.index +
                      8 * (7 - previousStep.to.rank.index))
                  .toString(),
              color: Colors.blueAccent)
          : null;
    });
  }

  void _selectNextStep({required SolutionStep step}) {
    var newFen = _fen;
    final board = positionToBoardArray(position: newFen);

    board[step.from.rank.index][step.from.file.index] = '';
    board[step.to.rank.index][step.to.file.index] = _playerHasWhite ? 'N' : 'n';
    newFen = fenFromBoard(board: board, playerHasWhite: _playerHasWhite);

    setState(() {
      _fen = newFen;
      _lastMoveArrow = BoardArrow(
          from: Cell.fromSquareIndex(
                  step.from.file.index + 8 * (7 - step.from.rank.index))
              .toString(),
          to: Cell.fromSquareIndex(
                  step.to.file.index + 8 * (7 - step.to.rank.index))
              .toString(),
          color: Colors.blueAccent);
    });
  }

  void _selectStartPosition() {
    setState(() {
      _fen = _startPosition;
      _lastMoveArrow = null;
    });
  }

  void _showHelp() {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: I18nText('app.title'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(''),
                  I18nText('help.rules_line_1'),
                  Text(''),
                  I18nText('help.rules_line_2'),
                  Text(''),
                  I18nText('help.rules_line_3'),
                  I18nText('help.rules_line_4'),
                  I18nText('help.rules_line_5'),
                  Text(''),
                  I18nText('help.rules_line_6'),
                  Text(''),
                  I18nText('help.rules_line_7'),
                  I18nText('help.rules_line_8'),
                ],
              ),
            ),
            actions: [
              DialogActionButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                textContent: I18nText('button.ok'),
                backgroundColor: Colors.greenAccent,
                textColor: Colors.white,
              )
            ],
          );
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
          IconButton(
            icon: Icon(Icons.help),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: Center(
        child: isPortraitLayout
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        I18nText(
                          'game.difficulty_label',
                          translationParams: {
                            'ennemiesCount': '$_ennemiesCount',
                          },
                          child: Text(
                            '',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SimpleChessBoard(
                    fen: _fen,
                    lastMoveToHighlight: _lastMoveArrow,
                    onMove: validateMove,
                    orientation: boardOrientation,
                    whitePlayerType: _whitePlayerType,
                    blackPlayerType: _blackPlayerType,
                    showCoordinatesZone: false,
                    onPromote: () async {
                      return null;
                    },
                    engineThinking: false,
                  ),
                  if (_gameEnded)
                    Padding(
                      child: SolutionZone(
                        solution: _solution,
                        onFirstPositionSelected: _selectStartPosition,
                        onPreviousStepSelected: _selectPreviousStep,
                        onNextStepSelected: _selectNextStep,
                      ),
                      padding: EdgeInsets.all(5.0),
                    )
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: I18nText(
                      'game.difficulty_label',
                      translationParams: {
                        'ennemiesCount': '$_ennemiesCount',
                      },
                      child: Text(
                        '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SimpleChessBoard(
                    fen: _fen,
                    lastMoveToHighlight: _lastMoveArrow,
                    onMove: validateMove,
                    orientation: boardOrientation,
                    whitePlayerType: _whitePlayerType,
                    blackPlayerType: _blackPlayerType,
                    showCoordinatesZone: false,
                    onPromote: () async {
                      return null;
                    },
                    engineThinking: false,
                  ),
                  if (_gameEnded)
                    Expanded(
                      child: Padding(
                        child: SolutionZone(
                          solution: _solution,
                          onFirstPositionSelected: _selectStartPosition,
                          onPreviousStepSelected: _selectPreviousStep,
                          onNextStepSelected: _selectNextStep,
                        ),
                        padding: EdgeInsets.all(5.0),
                      ),
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

class SolutionZone extends StatefulWidget {
  final List<SolutionStep> solution;
  final void Function(
      {required SolutionStep step,
      required SolutionStep? previousStep}) onPreviousStepSelected;
  final void Function({required SolutionStep step}) onNextStepSelected;
  final void Function() onFirstPositionSelected;

  const SolutionZone({
    Key? key,
    required this.solution,
    required this.onPreviousStepSelected,
    required this.onNextStepSelected,
    required this.onFirstPositionSelected,
  }) : super(key: key);

  @override
  State<SolutionZone> createState() => _SolutionZoneState();
}

class _SolutionZoneState extends State<SolutionZone> {
  var _currentIndex = -1;

  @override
  Widget build(BuildContext context) {
    final progressRatio = (_currentIndex + 1) / (widget.solution.length);

    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: I18nText(
              'solution.zone_title',
              child: Text(
                '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          LinearProgressIndicator(
            value: progressRatio,
            backgroundColor: Colors.redAccent,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  while (_currentIndex > 0) {
                    widget.onPreviousStepSelected(
                        step: widget.solution[_currentIndex],
                        previousStep: _currentIndex > 0
                            ? widget.solution[_currentIndex - 1]
                            : null);
                    setState(() {
                      _currentIndex--;
                    });
                  }
                  setState(() {
                    _currentIndex = -1;
                  });
                  widget.onFirstPositionSelected();
                },
                icon: Icon(Icons.skip_previous),
              ),
              IconButton(
                onPressed: () {
                  if (_currentIndex > -1) {
                    if (_currentIndex > 0) {
                      widget.onPreviousStepSelected(
                          step: widget.solution[_currentIndex],
                          previousStep: _currentIndex > 0
                              ? widget.solution[_currentIndex - 1]
                              : null);
                    } else {
                      setState(() {
                        _currentIndex = 0;
                      });
                      widget.onFirstPositionSelected();
                    }
                    setState(() {
                      _currentIndex--;
                    });
                  }
                },
                icon: Icon(Icons.arrow_back),
              ),
              IconButton(
                onPressed: () {
                  if (_currentIndex < widget.solution.length - 1) {
                    setState(() {
                      _currentIndex++;
                    });
                    widget.onNextStepSelected(
                        step: widget.solution[_currentIndex]);
                  }
                },
                icon: Icon(Icons.arrow_forward),
              ),
              IconButton(
                onPressed: () {
                  while (_currentIndex < widget.solution.length - 1) {
                    setState(() {
                      _currentIndex++;
                    });
                    widget.onNextStepSelected(
                        step: widget.solution[_currentIndex]);
                  }
                },
                icon: Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
