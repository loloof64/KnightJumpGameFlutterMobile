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
import 'package:flutter_i18n/loaders/decoders/yaml_decode_strategy.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const EMPTY_BOARD = '8/8/8/8/8/8/8/8 w - - 0 1';
const START_POSITION = '8/8/8/2n5/r3p3/8/1N3r2/3b4 w - - 0 1';

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
  var _chess = chesslib.Chess.fromFEN(START_POSITION);

  void validateMove({required ShortMove move}) {
    final playerSide = chesslib.Color.WHITE;
    final ennemySide = chesslib.Color.BLACK;
    final playerSideFen = 'w';

    final moveDefinition = {'from': move.from, 'to': move.to};
    final fromPiece = _chess.get(move.from);
    final toPiece = _chess.get(move.to);
    if (fromPiece == null) return;
    if (fromPiece.type != chesslib.PieceType.KNIGHT ||
        fromPiece.color != playerSide) return;
    if (toPiece == null) return;
    if (toPiece.color != ennemySide) return;
    final moveSuccess = _chess.move(moveDefinition);
    if (moveSuccess) {
      setState(() {
        var newFenParts = _chess.fen.split(' ');
        newFenParts[1] = playerSideFen;
        final newFen = newFenParts.join(' ');
        _chess = chesslib.Chess.fromFEN(newFen);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardOrientation =
        _blackAtBottom ? BoardColor.black : BoardColor.white;
    return Scaffold(
      appBar: AppBar(
        title: I18nText('app.title'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SimpleChessBoard(
              fen: _chess.fen,
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
