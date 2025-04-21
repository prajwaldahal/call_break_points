import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/game_model.dart';
import '../models/player_model.dart';
import '../models/round_score_model.dart';

class DatabaseHelper {
  static Database? _database;
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'call_break_game.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE games (game_id TEXT PRIMARY KEY)');
    await db.execute(
      'CREATE TABLE players (player_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)',
    );
    await db.execute('''
      CREATE TABLE participation (
        game_id TEXT NOT NULL,
        player_id INTEGER NOT NULL,
        FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE rounds (
        game_id TEXT NOT NULL,
        player_id INTEGER NOT NULL,
        round_num INTEGER NOT NULL,
        bid INTEGER NOT NULL,
        score REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES games(game_id),
        FOREIGN KEY (player_id) REFERENCES players(player_id),
        PRIMARY KEY (game_id, player_id, round_num)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_game_rounds ON rounds(game_id, round_num)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS rounds');
      await db.execute('DROP TABLE IF EXISTS participation');
      await db.execute('DROP TABLE IF EXISTS players');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> insertGame(Game game) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('games', {'game_id': game.id});
      for (final player in game.participants) {
        await txn.rawInsert('INSERT OR IGNORE INTO players (name) VALUES (?)', [
          player.name,
        ]);
        final playerId = await txn.query(
          'players',
          where: 'name = ?',
          whereArgs: [player.name],
        );
        final existingPlayer = Player.fromMap(playerId.first);
        await txn.insert('participation', {
          'game_id': game.id,
          'player_id': existingPlayer.playerId,
        });
      }
    });
  }

  Future<List<Game>> getAllGames() async {
    final db = await database;
    final games = await db.query('games');
    return Future.wait(
      games.map((gameMap) async {
        final participants = await getGameParticipants(
          gameMap['game_id'] as String,
        );
        return Game.fromMap(gameMap, participants);
      }),
    );
  }

  Future<void> deleteGame(String gameId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('rounds', where: 'game_id = ?', whereArgs: [gameId]);
      await txn.delete(
        'participation',
        where: 'game_id = ?',
        whereArgs: [gameId],
      );
      await txn.delete('games', where: 'game_id = ?', whereArgs: [gameId]);
    });
  }

  Future<List<Player>> getGameParticipants(String gameId) async {
    final db = await database;
    final participants = await db.rawQuery(
      'SELECT p.* FROM players p JOIN participation part ON p.player_id = part.player_id WHERE part.game_id = ?',
      [gameId],
    );
    return participants.map((map) => Player.fromMap(map)).toList();
  }

  Future<void> insertBid(RoundScore bid) async {
    final db = await database;
    await db.insert('rounds', {
      'game_id': bid.gameId,
      'player_id': bid.playerId,
      'round_num': bid.roundNumber,
      'bid': bid.bid,
      'score': 0.0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBid(
    String gameId,
    int playerId,
    int roundNum,
    int bid,
  ) async {
    final db = await database;
    await db.update(
      'rounds',
      {'bid': bid},
      where: 'game_id = ? AND player_id = ? AND round_num = ?',
      whereArgs: [gameId, playerId, roundNum],
    );
  }

  Future<void> updateRoundScore(
    String gameId,
    int playerId,
    int roundNum,
    double score,
  ) async {
    final db = await database;
    await db.update(
      'rounds',
      {'score': score},
      where: 'game_id = ? AND player_id = ? AND round_num = ?',
      whereArgs: [gameId, playerId, roundNum],
    );
  }

  Future<RoundScore?> getRoundScore(
    String gameId,
    int playerId,
    int roundNum,
  ) async {
    final db = await database;
    final result = await db.query(
      'rounds',
      where: 'game_id = ? AND player_id = ? AND round_num = ?',
      whereArgs: [gameId, playerId, roundNum],
    );
    if (result.isNotEmpty) {
      return RoundScore.fromMap(result.first);
    }
    return null;
  }

  Future<List<RoundScore>> getRoundsForGame(String gameId) async {
    final db = await database;
    final rounds = await db.query(
      'rounds',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    return rounds.map((round) => RoundScore.fromMap(round)).toList();
  }

  Future<void> deleteAllRounds(String gameId) async {
    final db = await database;
    await db.delete('rounds', where: 'game_id = ?', whereArgs: [gameId]);
  }

  Future<List<Map<String, dynamic>>> getSortedScores(String gameId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT p.name, SUM(r.score) AS totalScore
      FROM rounds r
      JOIN players p ON r.player_id = p.player_id
      WHERE r.game_id = ?
      GROUP BY r.player_id
      ORDER BY totalScore DESC
    ''',
      [gameId],
    );

    return result;
  }

  Future<void> deleteRoundsForGame(String gameId) async {
    final db = await database;
    await db.delete('rounds', where: 'game_id = ?', whereArgs: [gameId]);
  }

  Future<int> getCurrentRound(String gameId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(round_num) as maxRound FROM rounds WHERE game_id = ? AND score != 0.0',
      [gameId],
    );
    if (result.isNotEmpty && result.first["maxRound"] != null) {
      return (result.first["maxRound"] as int) + 1;
    }
    return 1;
  }
}
