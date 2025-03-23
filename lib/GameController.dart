import 'package:call_break_points/Services/databaseHelper.dart';
import 'package:get/get.dart';

class GameController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final _games = [].obs;

  get games => _games;

  void getGames() async {
    _games.value = await _databaseHelper.fetchGames();
  }

  void addGame(List<String> participants) async {
    String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    await _databaseHelper.insertGame(uniqueId, participants);
    getGames();
  }

  void deleteGame(String gameId) async {
    await _databaseHelper.deleteGame(gameId);
    getGames();
  }
}
