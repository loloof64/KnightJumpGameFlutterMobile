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
import 'package:chess/chess.dart' as chesslib;
import 'package:simple_chess_board/simple_chess_board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knight jump game',
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

  @override
  Widget build(BuildContext context) {
    final boardOrientation =
        _blackAtBottom ? BoardColor.black : BoardColor.white;
    return Scaffold(
      appBar: AppBar(
        title: Text('Knight jump game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SimpleChessBoard(
              fen: '8/8/8/8/8/8/8/8 w - - 0 1',
              onMove: ({required ShortMove move}) {},
              orientation: boardOrientation,
              whitePlayerType: _whitePlayerType,
              blackPlayerType: _blackPlayerType,
              showCoordinatesZone: false,
              onPromote: () async {},
              engineThinking: false,
            )
          ],
        ),
      ),
    );
  }
}
