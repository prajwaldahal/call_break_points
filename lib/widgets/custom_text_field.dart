import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomParticipantTextField extends StatelessWidget {
  final TextEditingController controller;
  final int participantNumber;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const CustomParticipantTextField({
    super.key,
    required this.controller,
    required this.participantNumber,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Participant $participantNumber',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      textCapitalization: TextCapitalization.words,
      validator: validator,
      inputFormatters: inputFormatters,
    );
  }
}
