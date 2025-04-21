import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/player_model.dart';
import '../models/round_score_model.dart';
import '../services/database_helper.dart';
import '../utils/round_state.dart';

class RoundRow {
  final int? roundNumber;
  final Map<int, double> values;
  RoundRow({this.roundNumber, required this.values});
}

class ScoreController extends GetxController {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  final _roundState = RoundState.loading.obs;
  final _currentRound = 1.obs;
  final _gameId = ''.obs;
  final _players = <Player>[].obs;
  final _bids = <int, int>{}.obs;
  final _scores = <int, double>{}.obs;
  final _rounds = <RoundScore>[].obs;
  final _roundRows = <RoundRow>[].obs;
  final _winnerList = <Map<String, dynamic>>[].obs;

  RoundState get roundState => _roundState.value;
  int get currentRound => _currentRound.value;
  String get gameId => _gameId.value;
  List<Player> get players => _players;
  Map<int, int> get bids => _bids;
  Map<int, double> get scores => _scores;
  List<RoundScore> get rounds => _rounds;
  List<RoundRow> get roundRows => _roundRows;
  List<Map<String, dynamic>> get winnerList => _winnerList;

  Future<void> initialize(String id) async {
    _gameId.value = id;
    _roundState.value = RoundState.loading;
    await _loadPlayersAndRounds();
    _currentRound.value = await dbHelper.getCurrentRound(id);
    if (_currentRound.value > 5) {
      _buildWinnerList(id);
    } else {
      _determineRoundState();
    }
  }

  Future<void> _loadPlayersAndRounds() async {
    try {
      _players.value = await dbHelper.getGameParticipants(_gameId.value);
      _bids
        ..clear()
        ..addEntries(_players.map((p) => MapEntry(p.playerId!, 1)));

      final data = await dbHelper.getRoundsForGame(_gameId.value);
      _rounds.assignAll(data);
      _buildRoundRows();
    } catch (e) {
      debugPrint('Error loading players/rounds: $e');
      _roundState.value = RoundState.error;
    }
  }

  void _determineRoundState() {
    final roundData =
        _rounds.where((r) => r.roundNumber == _currentRound.value).toList();
    if (roundData.length < _players.length) {
      _roundState.value = RoundState.biddingInProgress;
    } else {
      final allBidsExist = roundData.every((r) => r.bid != 0);
      final allScoresEntered = roundData.every((r) => r.score != 0.0);
      if (allBidsExist && !allScoresEntered) {
        _roundState.value = RoundState.scoringInProgress;
      } else {
        _roundState.value = RoundState.biddingInProgress;
      }
    }
  }

  void updateBid(int playerId, int value) {
    _bids[playerId] = value;
    update(['bid_$playerId']);
  }

  Future<void> submitBids() async {
    try {
      final newRounds =
          _players
              .map(
                (p) => RoundScore(
                  gameId: _gameId.value,
                  playerId: p.playerId!,
                  roundNumber: _currentRound.value,
                  bid: _bids[p.playerId] ?? 1,
                  score: 0.0,
                ),
              )
              .toList();

      for (final round in newRounds) {
        await dbHelper.insertBid(round);
      }

      _rounds.addAll(newRounds);
      _buildRoundRows();
      _roundState.value = RoundState.scoringInProgress;
    } catch (e) {
      debugPrint('Error submitting bids: $e');
      _roundState.value = RoundState.error;
    }
  }

  void updateScore(int playerId, double value) {
    _scores[playerId] = value;
  }

  Future<void> submitScores() async {
    final total = _scores.values.fold<double>(0.0, (sum, v) => sum + v);
    if (total != 13.0) {
      Get.snackbar(
        'Score Error',
        'Total achieved score must be exactly 13. Currently: $total',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      for (final p in _players) {
        final finalScore = _calculateFinalScore(
          _bids[p.playerId] ?? 0,
          _scores[p.playerId] ?? 0.0,
        );
        await dbHelper.updateRoundScore(
          _gameId.value,
          p.playerId!,
          _currentRound.value,
          finalScore,
        );
      }

      final data = await dbHelper.getRoundsForGame(_gameId.value);
      _rounds.assignAll(data);
      _buildRoundRows();

      if (_currentRound.value == 5) {
        _buildWinnerList(_gameId.value);
      } else {
        _currentRound.value++;
        _bids.clear();
        _scores.clear();
        _bids.addEntries(_players.map((p) => MapEntry(p.playerId!, 1)));
        _roundState.value = RoundState.biddingInProgress;
      }
    } catch (e) {
      debugPrint('Error submitting scores: $e');
      _roundState.value = RoundState.error;
    }
  }

  double _calculateFinalScore(int bid, double achieved) {
    if (achieved >= bid) return bid + (achieved - bid) * 0.1;
    return -bid.toDouble();
  }

  void _buildRoundRows() {
    final mapPerRound = <int, Map<int, double>>{};
    for (final r in _rounds) {
      mapPerRound.putIfAbsent(r.roundNumber, () => {});
      mapPerRound[r.roundNumber]![r.playerId] =
          r.score == 0 ? r.bid.toDouble() : r.score;
    }

    final rows = <RoundRow>[];
    for (final k in mapPerRound.keys.toList()..sort()) {
      rows.add(RoundRow(roundNumber: k, values: mapPerRound[k]!));
    }

    if (_currentRound.value > 1) {
      final totals = <int, double>{};
      for (final r in _rounds) {
        totals[r.playerId] = (totals[r.playerId] ?? 0) + r.score;
      }
      rows.add(RoundRow(roundNumber: null, values: totals));
    }

    _roundRows.assignAll(rows);
  }

  Future<void> resetGame() async {
    try {
      await dbHelper.deleteRoundsForGame(_gameId.value);
      _currentRound.value = 1;
      _rounds.clear();
      _roundRows.clear();
      _winnerList.clear();
      _bids.clear();
      _scores.clear();
      _bids.addEntries(_players.map((p) => MapEntry(p.playerId!, 1)));
      _roundState.value = RoundState.biddingInProgress;
    } catch (e) {
      debugPrint('Error resetting game: $e');
      _roundState.value = RoundState.error;
    }
  }

  Future<void> _buildWinnerList(String id) async {
    _roundState.value = RoundState.finalized;
    final raw = await dbHelper.getSortedScores(id);
    _winnerList.assignAll(raw);
  }
}
