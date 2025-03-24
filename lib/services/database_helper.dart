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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games (
        game_id TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE players (
        player_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE participation (
        game_id TEXT NOT NULL,
        player_id INTEGER NOT NULL,
        PRIMARY KEY (game_id, player_id),
        FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE rounds (
        game_id TEXT NOT NULL,
        player_id INTEGER NOT NULL,
        round_num INTEGER NOT NULL CHECK (round_num BETWEEN 1 AND 5),
        bid INTEGER NOT NULL CHECK (bid > 0),
        score INTEGER NOT NULL CHECK (score > 0),
        PRIMARY KEY (game_id, player_id, round_num),
        FOREIGN KEY (game_id) REFERENCES games(game_id),
        FOREIGN KEY (player_id) REFERENCES players(player_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_game_rounds ON rounds(game_id, round_num)
    ''');
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
      await txn.insert('games', {'game_id': game.gameId});

      for (final player in game.participants) {
        final playerId = await txn.rawInsert(
          '''
          INSERT OR IGNORE INTO players (name) 
          VALUES (?)
        ''',
          [player.name],
        );

        final result = await txn.query(
          'players',
          where: 'name = ?',
          whereArgs: [player.name],
        );
        final existingPlayer = Player.fromMap(result.first);

        await txn.insert('participation', {
          'game_id': game.gameId,
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

  Future<List<Player>> getGameParticipants(String gameId) async {
    final db = await database;
    final participants = await db.rawQuery(
      '''
      SELECT p.* 
      FROM players p
      JOIN participation part ON p.player_id = part.player_id
      WHERE part.game_id = ? 
    ''',
      [gameId],
    );
    return participants.map((map) => Player.fromMap(map)).toList();
  }

  Future<void> insertRoundScores(List<RoundScore> scores) async {
    final db = await database;
    final batch = db.batch();
    for (final score in scores) {
      batch.insert('rounds', score.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<RoundScore>> getGameScores(String gameId) async {
    final db = await database;
    final scores = await db.query(
      'rounds',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
    return scores.map((map) => RoundScore.fromMap(map)).toList();
  }

  Future<Map<int, int>> calculateTotalScores(String gameId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT player_id, SUM(score) AS total
      FROM rounds
      WHERE game_id = ? 
      GROUP BY player_id
    ''',
      [gameId],
    );

    return {
      for (var row in result) row['player_id'] as int: row['total'] as int,
    };
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

  Future<List<RoundScore>> getPlayerRounds(String gameId, int playerId) async {
    final db = await database;
    final rounds = await db.query(
      'rounds',
      where: 'game_id = ? AND player_id = ?',
      whereArgs: [gameId, playerId],
    );
    return rounds.map((map) => RoundScore.fromMap(map)).toList();
  }

  Future<RoundScore?> getRoundScore(
    String gameId,
    int playerId,
    int roundNum,
  ) async {
    final db = await database;
    final rounds = await db.query(
      'rounds',
      where: 'game_id = ? AND player_id = ? AND round_num = ?',
      whereArgs: [gameId, playerId, roundNum],
    );
    if (rounds.isNotEmpty) {
      return RoundScore.fromMap(rounds.first);
    }
    return null;
  }

  Future<void> updateRound(RoundScore round) async {
    final db = await database;
    await db.update(
      'rounds',
      round.toMap(),
      where: 'game_id = ? AND player_id = ? AND round_num = ?',
      whereArgs: [round.gameId, round.playerId, round.roundNumber],
    );
  }
}
