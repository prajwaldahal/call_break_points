import 'package:get/get.dart';

import '../models/game_model.dart';
import '../services/database_helper.dart';

class GameController extends GetxController {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final RxList<Game> _games = <Game>[].obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _isLoading = false.obs;

  List<Game> get games => _games;
  String get errorMessage => _errorMessage.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    getGames();
  }

  Future<void> getGames() async {
    try {
      _isLoading.value = true;
      final fetchedGames = await _databaseHelper.getAllGames();
      _games.assignAll(fetchedGames.reversed.toList());
      _errorMessage.value = '';
    } catch (e) {
      _errorMessage.value = 'Failed to load games: ${e.toString()}';
      Get.snackbar('Error', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> addGame(Game game) async {
    try {
      _isLoading.value = true;
      await _databaseHelper.insertGame(game);
      _games.insert(0, game);
    } catch (e) {
      _errorMessage.value = 'Failed to add game: ${e.toString()}';
      Get.snackbar('Error', _errorMessage.value);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      _isLoading.value = true;
      await _databaseHelper.deleteGame(gameId);
      _games.removeWhere((game) => game.id == gameId);
      Get.snackbar('Success', 'Game deleted successfully');
    } catch (e) {
      _errorMessage.value = 'Failed to delete game: ${e.toString()}';
      Get.snackbar('SORRY', 'Error Deleting game');
    } finally {
      _isLoading.value = false;
    }
  }
}
