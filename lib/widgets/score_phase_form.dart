import 'package:flutter/material.dart';

import '../controller/score_controller.dart';
import '../models/player_model.dart';

class ScorePhaseForm extends StatefulWidget {
  final ScoreController controller;
  const ScorePhaseForm({super.key, required this.controller});

  @override
  _ScorePhaseFormState createState() => _ScorePhaseFormState();
}

class _ScorePhaseFormState extends State<ScorePhaseForm> {
  late List<FocusNode> _focusNodes;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.controller.players.length,
      (_) => FocusNode(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: List.generate(widget.controller.players.length, (index) {
          Player player = widget.controller.players[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextFormField(
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              textInputAction:
                  index < widget.controller.players.length - 1
                      ? TextInputAction.next
                      : TextInputAction.done,
              decoration: InputDecoration(
                labelText: player.name,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.controller.updateScore(
                  player.playerId!,
                  double.tryParse(value) ?? 0.0,
                );
              },
              onFieldSubmitted: (_) {
                if (index < _focusNodes.length - 1) {
                  _focusNodes[index + 1].requestFocus();
                } else {
                  _focusNodes[index].unfocus();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a score for ${player.name}';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          );
        }),
      ),
    );
  }
}
