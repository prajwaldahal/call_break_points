import 'player_model.dart';

class Game {
  final String _gameId;
  final List<Player> participants;

  String get gameId => _gameId;

  Game({required this.participants})
    : _gameId = DateTime.now().millisecondsSinceEpoch.toString();

  factory Game.fromMap(Map<String, dynamic> map, List<Player> participants) =>
      Game(participants: participants);
}
