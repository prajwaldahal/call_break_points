import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/game_controller.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';
import '../widgets/custom_text_field.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _participantControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  @override
  void dispose() {
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameController = Get.put(GameController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Break Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: gameController.getGames,
          ),
        ],
      ),
      body: _buildGameList(gameController),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGameDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGameList(GameController gameController) {
    return Obx(
      () =>
          gameController.games.isEmpty
              ? const Center(child: Text('No games found. Add a new game!'))
              : ListView.builder(
                itemCount: gameController.games.length,
                itemBuilder: (context, index) {
                  final game = gameController.games[index];
                  return _buildGameTile(gameController, game);
                },
              ),
    );
  }

  Widget _buildGameTile(GameController gameController, Game game) {
    return Dismissible(
      key: Key(game.gameId),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (direction) => _showDeleteConfirmationDialog(),
      onDismissed: (direction) => gameController.deleteGame(game.gameId),
      child: ListTile(
        title: Text(game.gameId),
        subtitle: _buildPlayerNames(game),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed('/game-detail', arguments: game),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildPlayerNames(Game game) {
    return Text(
      'Players: ${game.participants.map((p) => p.name).join(', ')}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                content: const Text(
                  'Are you sure you want to delete this game?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showAddGameDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            child: _buildAddGameDialogContent(),
          ),
    );
  }

  Widget _buildAddGameDialogContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Game',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(children: _buildParticipantTextFields()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _onStartGameButtonPressed(),
            child: const Text('Start Game'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildParticipantTextFields() {
    return List.generate(4, (index) {
      return Column(
        children: [
          CustomParticipantTextField(
            controller: _participantControllers[index],
            participantNumber: index + 1,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
        ],
      );
    });
  }

  void _onStartGameButtonPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final participants = _createPlayersFromControllers();
      final game = Game(participants: participants);
      final gameController = Get.find<GameController>();
      gameController.addGame(game);
      Navigator.pop(context);
    }
  }

  List<Player> _createPlayersFromControllers() {
    return List.generate(
      4,
      (index) => Player(name: _participantControllers[index].text),
    );
  }
}
