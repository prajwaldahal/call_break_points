class Player {
  final int? playerId;
  final String name;

  Player({this.playerId, required this.name});

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(playerId: map['player_id'], name: map['name']);
  }

  Map<String, dynamic> toMap() => {
    if (playerId != null) 'player_id': playerId,
    'name': name,
  };
}
