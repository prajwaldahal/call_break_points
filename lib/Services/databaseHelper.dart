import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<String> get _databasePath async {
    final dbFolder = await getDatabasesPath();
    return join(dbFolder, 'call_break_game.db');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await _databasePath;
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE games (
      game_id TEXT PRIMARY KEY
    );
    CREATE TABLE players (
      player_id INTEGER PRIMARY KEY AUTOINCREMENT,
      game_id TEXT NOT NULL,
      name TEXT NOT NULL,
      FOREIGN KEY (game_id) REFERENCES games(game_id)
    );
    CREATE TABLE round_scores (
      round_id INTEGER NOT NULL,
      player_id INTEGER NOT NULL,
      bid INTEGER NOT NULL CHECK(bid > 0),
      score INTEGER NOT NULL CHECK(score > 0),
      PRIMARY KEY (round_id, player_id),
      FOREIGN KEY (round_id) REFERENCES rounds(round_id),
      FOREIGN KEY (player_id) REFERENCES players(player_id)
    );
    ''');
  }

  Future<int> insertGame(String gameId, List<String> names) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        await txn.insert('games', {'game_id': gameId});
        await _insertPlayers(txn, gameId, names);
      });
      return 1;
    } catch (e) {
      throw Exception('Error inserting game: $e');
    }
  }

  Future<int> _insertPlayers(
    Transaction txn,
    String gameId,
    List<String> names,
  ) async {
    final db = txn;

    try {
      for (var name in names) {
        var existingPlayer = await db.query(
          'players',
          where: 'game_id = ? AND name = ?',
          whereArgs: [gameId, name],
        );

        if (existingPlayer.isEmpty) {
          await db.insert('players', {'game_id': gameId, 'name': name});
        }
      }
      return 1;
    } catch (e) {
      throw Exception('Error inserting players: $e');
    }
  }

  Future<int> insertRoundScore(
    int roundId,
    int playerId,
    int bid,
    int score,
  ) async {
    final db = await database;

    try {
      return await db.insert('round_scores', {
        'round_id': roundId,
        'player_id': playerId,
        'bid': bid,
        'score': score,
      });
    } catch (e) {
      throw Exception('Error inserting round score: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchGames() async {
    final db = await database;

    try {
      return await db.query('games');
    } catch (e) {
      throw Exception('Error fetching games: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPlayers(String gameId) async {
    final db = await database;

    try {
      return await db.query(
        'players',
        where: 'game_id = ?',
        whereArgs: [gameId],
      );
    } catch (e) {
      throw Exception('Error fetching players: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRoundScores(int roundId) async {
    final db = await database;

    try {
      return await db.query(
        'round_scores',
        where: 'round_id = ?',
        whereArgs: [roundId],
      );
    } catch (e) {
      throw Exception('Error fetching round scores: $e');
    }
  }

  Future<void> updateRoundScore(
    int roundId,
    int playerId,
    int bid,
    int score,
  ) async {
    final db = await database;

    try {
      await db.update(
        'round_scores',
        {'bid': bid, 'score': score},
        where: 'round_id = ? AND player_id = ?',
        whereArgs: [roundId, playerId],
      );
    } catch (e) {
      throw Exception('Error updating round score: $e');
    }
  }

  Future<void> deleteGame(String gameId) async {
    final db = await database;

    try {
      await db.delete('games', where: 'game_id = ?', whereArgs: [gameId]);
      await db.delete('players', where: 'game_id = ?', whereArgs: [gameId]);
      await db.delete(
        'round_scores',
        where: 'round_id IN (SELECT round_id FROM rounds WHERE game_id = ?)',
        whereArgs: [gameId],
      );
    } catch (e) {
      throw Exception('Error deleting game: $e');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
