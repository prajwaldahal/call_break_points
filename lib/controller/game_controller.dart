// lib/controllers/game_controller.dart
import 'package:get/get.dart';
import '../services/database_helper.dart';
import '../models/game_model.dart';

class GameController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final RxList<Game> _games = <Game>[].obs;

  List<Game> get games => _games;

  @override
  void onInit() {
    super.onInit();
    getGames();
  }

  void getGames() async {
    var fetchedGames = await _databaseHelper.getAllGames();
    _games.assignAll(fetchedGames);
  }

  void addGame(Game game) async {
    await _databaseHelper.insertGame(game);
    getGames();
  }

  void deleteGame(String gameId) async {
    await _databaseHelper.deleteGame(gameId);
    _games.removeWhere((game) => game.gameId == gameId);
  }
}
