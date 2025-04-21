import 'package:call_break_points/models/player_model.dart';

class Game {
  final String id;
  final List<Player> participants;

  Game({required this.participants, String? gameId})
    : id = gameId ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory Game.fromMap(Map<String, dynamic> map, List<Player> participants) {
    return Game(gameId: map['game_id'], participants: participants);
  }

  Map<String, dynamic> toMap() => {'game_id': id};
}
