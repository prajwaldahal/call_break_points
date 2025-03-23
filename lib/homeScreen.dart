import 'package:call_break_points/GameController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final gameController = Get.put(GameController());
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddGameDialog(context, gameController);
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text('Call Break Points')),
      body: Obx(
        () => ListView.builder(
          itemCount: gameController.games.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(gameController.games[index]['game_id']),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  gameController.deleteGame(
                    gameController.games[index]['game_id'],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void showAddGameDialog(BuildContext context, GameController gameController) {
    final TextEditingController _gameIdController = TextEditingController();
    final TextEditingController _participant1Controller =
        TextEditingController();
    final TextEditingController _participant2Controller =
        TextEditingController();
    final TextEditingController _participant3Controller =
        TextEditingController();
    final TextEditingController _participant4Controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              spacing: 20.0,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Game',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _gameIdController,
                  decoration: const InputDecoration(
                    labelText: 'Game Id',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _participant1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Participant 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _participant2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Participant 2',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _participant3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Participant 3',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: _participant4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Participant 4',
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        List<String> participants = [
                          _participant1Controller.text,
                          _participant2Controller.text,
                          _participant3Controller.text,
                          _participant4Controller.text,
                        ];
                        gameController.addGame(participants);
                        Navigator.pop(context);
                      },
                      child: const Text('Add Game'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
