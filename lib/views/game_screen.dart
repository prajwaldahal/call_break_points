import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/score_controller.dart';
import '../models/player_model.dart';
import '../utils/round_state.dart';
import '../widgets/score_phase_form.dart';

class GameScreen extends StatelessWidget {
  final ScoreController controller = Get.put(ScoreController());

  GameScreen({super.key}) {
    final id = Get.arguments as String;
    controller.initialize(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _GameAppBar(controller: controller),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade50],
          ),
        ),
        child: Obx(() {
          switch (controller.roundState) {
            case RoundState.error:
              return const Center(child: Text('Error loading game data'));
            case RoundState.biddingInProgress:
            case RoundState.scoringInProgress:
            case RoundState.finalized:
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ListBody(
                      children: [
                        StepIndicator(controller: controller),
                        const SizedBox(height: 24),
                        PhaseCard(controller: controller),
                        const SizedBox(height: 24),
                        if (controller.roundState == RoundState.finalized &&
                            controller.winnerList.isNotEmpty)
                          WinnerTable(controller: controller),
                        const SizedBox(height: 24),
                        RoundTable(controller: controller),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            case RoundState.loading:
              return const Center(child: CircularProgressIndicator());
          }
        }),
      ),
    );
  }
}

class _GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ScoreController controller;
  const _GameAppBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Obx(
        () => Column(
          children: [
            Text(
              controller.currentRound < 6 ? 'CURRENT ROUND' : 'WINNER LIST',
              style: _appBarSubtitleStyle,
            ),
            Text('${controller.currentRound}', style: _appBarTitleStyle),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.restart_alt, color: Colors.grey.shade700),
          onPressed:
              () => Get.defaultDialog(
                title: 'Confirm Reset',
                titleStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                ),
                middleText:
                    'This will delete all round data and start over. Continue?',
                middleTextStyle: const TextStyle(fontFamily: 'Roboto'),
                textConfirm: 'Yes',
                textCancel: 'No',
                confirmTextColor: Colors.white,
                onConfirm: () {
                  controller.resetGame();
                  Get.back();
                },
              ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  TextStyle get _appBarTitleStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  TextStyle get _appBarSubtitleStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );
}

class StepIndicator extends StatelessWidget {
  final ScoreController controller;
  const StepIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStep('Bidding', Icons.gavel, RoundState.biddingInProgress),
            _stepLine(),
            _buildStep('Scoring', Icons.score, RoundState.scoringInProgress),
            _stepLine(),
            _buildStep('Results', Icons.emoji_events, RoundState.finalized),
          ],
        ),
      );
    });
  }

  Widget _buildStep(String label, IconData icon, RoundState state) {
    final isActive = controller.roundState.index >= state.index;
    final isCurrent = controller.roundState == state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: isActive ? _getStepColor(state) : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: isCurrent ? Colors.black : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepColor(RoundState state) {
    switch (state) {
      case RoundState.biddingInProgress:
        return Colors.blue.shade600;
      case RoundState.scoringInProgress:
        return Colors.green.shade600;
      case RoundState.finalized:
        return Colors.orange.shade600;
      default:
        return Colors.grey;
    }
  }

  Widget _stepLine() => Container(
    width: 40,
    height: 2,
    margin: const EdgeInsets.only(bottom: 20),
    color: Colors.grey.shade300,
  );
}

class PhaseCard extends StatelessWidget {
  final ScoreController controller;
  const PhaseCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.roundState) {
        case RoundState.biddingInProgress:
          return BidPhaseCard(controller: controller);
        case RoundState.scoringInProgress:
          return ScorePhaseCard(controller: controller);
        default:
          return const SizedBox.shrink();
      }
    });
  }
}

class BidPhaseCard extends StatelessWidget {
  final ScoreController controller;
  const BidPhaseCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Set Bids',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            ...controller.players.map(
              (p) => BidRow(player: p, controller: controller),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade50,
                    foregroundColor: Colors.blueGrey.shade800,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.blueGrey.shade100,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onPressed: controller.submitBids,
                  child: const Text(
                    'Confirm Bids',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BidRow extends StatelessWidget {
  final Player player;
  final ScoreController controller;
  const BidRow({super.key, required this.player, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: GetBuilder<ScoreController>(
              id: 'bid_${player.playerId}',
              builder: (_) {
                final bid = controller.bids[player.playerId] ?? 1;
                return SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.blueGrey.shade600,
                    inactiveTrackColor: Colors.blueGrey.shade100,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                      elevation: 2,
                    ),
                    trackHeight: 4,
                    overlayColor: Colors.transparent,
                  ),
                  child: Slider(
                    min: 1,
                    max: 8,
                    divisions: 7,
                    value: bid.toDouble(),
                    label: '$bid',
                    onChanged:
                        (v) =>
                            controller.updateBid(player.playerId!, v.toInt()),
                  ),
                );
              },
            ),
          ),
          GetBuilder<ScoreController>(
            id: 'bid_${player.playerId}',
            builder: (_) {
              final bid = controller.bids[player.playerId] ?? 1;
              return SizedBox(
                width: 36,
                child: Text(
                  '$bid',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScorePhaseCard extends StatelessWidget {
  final ScoreController controller;
  const ScorePhaseCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.score, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text(
                  'Scoring Phase',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ScorePhaseForm(controller: controller),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text('Submit Scores'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: controller.submitScores,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundTable extends StatelessWidget {
  final ScoreController controller;
  const RoundTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 32,
            horizontalMargin: 16,
            headingTextStyle: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            dataTextStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            columns: [
              DataColumn(label: _buildHeaderCell('Round')),
              ...controller.players.map(
                (p) => DataColumn(label: _buildHeaderCell(p.name)),
              ),
            ],
            rows:
                controller.roundRows.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _buildRoundCell(
                          row.roundNumber == null
                              ? 'Total'
                              : '${row.roundNumber}',
                          isHeader: true,
                        ),
                      ),
                      ...controller.players.map((p) {
                        final v = row.values[p.playerId] ?? 0.0;
                        return DataCell(_buildScoreCell(v));
                      }),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, textAlign: TextAlign.center),
  );

  Widget _buildRoundCell(String text, {bool isHeader = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        color: isHeader ? Colors.blue.shade600 : Colors.black,
      ),
    ),
  );

  Widget _buildScoreCell(double value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: value < 0 ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          value < 0
              ? Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              )
              : Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }
}

class WinnerTable extends StatelessWidget {
  final ScoreController controller;
  const WinnerTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'Final Standings',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...controller.winnerList.asMap().entries.map((entry) {
              final index = entry.key;
              final m = entry.value;
              final name = m['name'] as String;
              final total = m['totalScore'] as double;
              final isFirst = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isFirst ? Colors.amber.shade50 : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: _buildMedal(index + 1),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                      color:
                          isFirst
                              ? Colors.amber.shade800
                              : Colors.grey.shade800,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          total < 0 ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      total.toStringAsFixed(1),
                      style: TextStyle(
                        color:
                            total < 0
                                ? Colors.red.shade600
                                : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMedal(int position) {
    switch (position) {
      case 1:
        return Icon(Icons.emoji_events, color: Colors.amber);
      case 2:
        return Icon(Icons.emoji_events, color: Colors.grey);
      case 3:
        return Icon(Icons.emoji_events, color: Colors.brown);
      default:
        return Icon(Icons.star, color: Colors.blue.shade300);
    }
  }
}
