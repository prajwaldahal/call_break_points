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
      body: Obx(() {
        switch (controller.roundState) {
          case RoundState.error:
            return const Center(child: Text('Error loading game data'));
          case RoundState.biddingInProgress:
          case RoundState.scoringInProgress:
          case RoundState.finalized:
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  StepIndicator(controller: controller),
                  const SizedBox(height: 16),
                  PhaseCard(controller: controller),
                  const SizedBox(height: 24),
                  RoundTable(controller: controller),
                  const SizedBox(height: 24),
                  if (controller.roundState == RoundState.finalized &&
                      controller.winnerList.isNotEmpty)
                    Center(child: WinnerTable(controller: controller)),
                ],
              ),
            );
          case RoundState.loading:
            return const Center(child: CircularProgressIndicator());
        }
      }),
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
        () => Text('Round ${controller.currentRound}', style: _appBarTextStyle),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed:
              () => Get.defaultDialog(
                title: 'Confirm Reset',
                middleText:
                    'This will delete all round data and start over. Continue?',
                textConfirm: 'Yes',
                textCancel: 'No',
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

  TextStyle get _appBarTextStyle => TextStyle(
    fontFamily: 'Roboto',
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
}

class StepIndicator extends StatelessWidget {
  final ScoreController controller;
  const StepIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Flex(
        direction: Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepCircle(
            'B',
            controller.roundState == RoundState.biddingInProgress,
          ),
          _stepLine(),
          _stepCircle(
            'S',
            controller.roundState == RoundState.scoringInProgress,
          ),
          _stepLine(),
          _stepCircle('W', controller.roundState == RoundState.finalized),
        ],
      );
    });
  }

  Widget _stepCircle(String label, bool active) => CircleAvatar(
    radius: 20,
    backgroundColor: active ? Get.theme.primaryColor : Colors.grey.shade400,
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );

  Widget _stepLine() => SizedBox(
    width: 40,
    height: 2,
    child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade400)),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bidding Phase',
              style: Get.textTheme.titleMedium!.copyWith(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 8),
            ...controller.players.map(
              (p) => BidRow(player: p, controller: controller),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.submitBids,
              child: const Text('Submit Bids'),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 200,
            child: GetBuilder<ScoreController>(
              id: 'bid_${player.playerId}',
              builder: (_) {
                final bid = controller.bids[player.playerId] ?? 1;
                return Slider(
                  min: 1,
                  max: 8,
                  divisions: 7,
                  value: bid.toDouble(),
                  label: '$bid',
                  onChanged:
                      (v) => controller.updateBid(player.playerId!, v.toInt()),
                );
              },
            ),
          ),
          GetBuilder<ScoreController>(
            id: 'bid_${player.playerId}',
            builder: (_) {
              final bid = controller.bids[player.playerId] ?? 1;
              return Text(
                '$bid',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  fontSize: 18,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scoring Phase',
              style: Get.textTheme.titleMedium!.copyWith(fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 8),
            ScorePhaseForm(controller: controller),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.submitScores,
              child: const Text('Submit Scores'),
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
    final columns = <DataColumn>[
      DataColumn(
        label: Text(
          'Round',
          style: Get.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
            fontSize: 16,
          ),
        ),
      ),
      ...controller.players.map(
        (p) => DataColumn(
          label: Text(
            p.name,
            style: Get.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              fontSize: 16,
            ),
          ),
        ),
      ),
    ];

    final rows =
        controller.roundRows.map((row) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  row.roundNumber == null
                      ? 'Total'
                      : 'Round ${row.roundNumber}',
                  style: Get.textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    fontSize: 16,
                  ),
                ),
              ),
              ...controller.players.map((p) {
                final v = row.values[p.playerId] ?? 0.0;
                return DataCell(
                  v < 0
                      ? CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 18,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              v.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      )
                      : Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                );
              }),
            ],
          );
        }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: columns, rows: rows),
    );
  }
}

class WinnerTable extends StatelessWidget {
  final ScoreController controller;
  const WinnerTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.winnerList.isEmpty) return const SizedBox.shrink();

    final columns = const [
      DataColumn(
        label: Text(
          'Player',
          style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
        ),
      ),
      DataColumn(
        label: Text(
          'Score',
          style: TextStyle(fontFamily: 'Roboto', fontSize: 16),
        ),
      ),
    ];

    final rows =
        controller.winnerList
            .asMap()
            .map((index, m) {
              final name = m['name'] as String;
              final total = m['totalScore'] as double;
              final position = index + 1;

              return MapEntry(
                index,
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          _getPositionIcon(position),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      total < 0
                          ? CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 18,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  total.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          )
                          : Text(
                            total.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                            ),
                          ),
                    ),
                  ],
                ),
              );
            })
            .values
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Winners',
              style: Get.textTheme.titleMedium!.copyWith(fontFamily: 'Roboto'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: columns, rows: rows),
        ),
      ],
    );
  }

  Widget _getPositionIcon(int position) {
    switch (position) {
      case 1:
        return const Icon(Icons.military_tech, color: Colors.yellow);
      case 2:
        return const Icon(Icons.military_tech, color: Colors.grey);
      case 3:
        return const Icon(Icons.military_tech, color: Colors.brown);
      default:
        return const Icon(Icons.star_border, color: Colors.grey);
    }
  }
}
