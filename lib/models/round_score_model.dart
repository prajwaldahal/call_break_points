class RoundScore {
  final String gameId;
  final int playerId;
  final int roundNumber;
  final int bid;
  final int score;

  RoundScore({
    required this.gameId,
    required this.playerId,
    required this.roundNumber,
    required this.bid,
    required this.score,
  });

  factory RoundScore.fromMap(Map<String, dynamic> map) => RoundScore(
    gameId: map['game_id'],
    playerId: map['player_id'],
    roundNumber: map['round_num'],
    bid: map['bid'],
    score: map['score'],
  );

  Map<String, dynamic> toMap() => {
    'game_id': gameId,
    'player_id': playerId,
    'round_num': roundNumber,
    'bid': bid,
    'score': score,
  };
}
