import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/game_controller.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';
import '../widgets/custom_text_field.dart';

class HomePage extends StatelessWidget {
  final GameController gameController = Get.put(GameController());

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (gameController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (gameController.errorMessage.isNotEmpty) {
          return _buildErrorState(gameController.errorMessage);
        }

        if (gameController.games.isEmpty) {
          return _buildEmptyState();
        }

        return _buildGameList();
      }),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Call Breaks',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      ),
      actions: [RefreshButton()],
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorState(error: error);
  }

  Widget _buildEmptyState() {
    return const EmptyState();
  }

  Widget _buildGameList() {
    return GameList(gameController: gameController);
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showAddGameDialog(context),
      child: const Icon(Icons.add, size: 30),
    );
  }

  void _showAddGameDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final dialogController = AddGameDialogController();

    Get.dialog(
      AddGameDialog(
        formKey: formKey,
        controller: dialogController,
        onSubmit: () => _handleFormSubmission(formKey, dialogController),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _handleFormSubmission(
    GlobalKey<FormState> formKey,
    AddGameDialogController dialogController,
  ) async {
    if (formKey.currentState?.validate() ?? false) {
      final participants = dialogController.getValidatedParticipants();
      if (participants != null) {
        await gameController.addGame(Game(participants: participants));
        Get.back();
        Get.snackbar('Success', 'New game created');
      }
    }
  }
}

class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    final gameController = Get.find<GameController>();
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: "Refresh",
      onPressed: () async {
        await gameController.getGames();
        if (gameController.errorMessage.isNotEmpty) {
          Get.snackbar(
            'Error',
            gameController.errorMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar('Refreshed', 'Game list updated');
        }
      },
    );
  }
}

class ErrorState extends StatelessWidget {
  final String error;
  const ErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () {
              final gameController = Get.find<GameController>();
              gameController.getGames();
            },
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.games_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No games found',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to start a new game!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class GameList extends StatelessWidget {
  final GameController gameController;
  const GameList({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: gameController.games.length,
      itemBuilder: (context, index) {
        final game = gameController.games[index];
        return Dismissible(
          key: Key(game.id.toString()),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(),
          onDismissed: (direction) {
            gameController.deleteGame(game.id);
            Get.snackbar('Game Deleted', 'The game has been deleted');
          },
          background: Container(
            color: Colors.red,
            child: const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
          child: GameListTile(game: game),
        );
      },
    );
  }

  Future<bool> _confirmDelete() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('This will permanently delete the game record'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class GameListTile extends StatelessWidget {
  final Game game;
  const GameListTile({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text('Game ${game.id}'),
        subtitle: Text(
          'Participants: ${game.participants.map((p) => p.name).join(', ')}',
        ),
        onTap: () => Get.toNamed('/game-detail', arguments: game.id),
      ),
    );
  }
}

class AddGameDialogController {
  final List<TextEditingController> controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  List<Player>? getValidatedParticipants() {
    final participants =
        controllers.map((c) => Player(name: c.text.trim())).toList();

    if (participants.any((p) => p.name.isEmpty)) {
      Get.snackbar('Error', 'All player names are required');
      return null;
    }

    final uniqueNames = participants.map((p) => p.name).toSet();
    if (uniqueNames.length < participants.length) {
      Get.snackbar('Error', 'Player names must be unique');
      return null;
    }

    return participants;
  }
}

class AddGameDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AddGameDialogController controller;
  final VoidCallback onSubmit;

  const AddGameDialog({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New Game',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildForm(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      child: Column(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomParticipantTextField(
              controller: controller.controllers[index],
              participantNumber: index + 1,
              currentFocusNode: controller.focusNodes[index],
              nextFocusNode:
                  index < 3 ? controller.focusNodes[index + 1] : null,
              autoFocus: index == 0,
              validator: _validateParticipantName,
            ),
          );
        }),
      ),
    );
  }

  String? _validateParticipantName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter player name';
    if (value.length > 20) return 'Name too long (max 20 chars)';
    return null;
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final isLoading = Get.find<GameController>().isLoading;
      return ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: isLoading ? Colors.grey : null,
        ),
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Start Game'),
      );
    });
  }
}
