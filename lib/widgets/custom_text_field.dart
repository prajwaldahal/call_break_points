import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomParticipantTextField extends StatefulWidget {
  final TextEditingController controller;
  final int participantNumber;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? currentFocusNode;
  final FocusNode? nextFocusNode;
  final bool autoFocus;
  final String? hintText;

  const CustomParticipantTextField({
    super.key,
    required this.controller,
    required this.participantNumber,
    this.validator,
    this.inputFormatters,
    this.currentFocusNode,
    this.nextFocusNode,
    this.autoFocus = false,
    this.hintText,
  });

  @override
  State<CustomParticipantTextField> createState() => _CustomParticipantTextFieldState();
}

class _CustomParticipantTextFieldState extends State<CustomParticipantTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.currentFocusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.currentFocusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: widget.autoFocus,
      textInputAction: widget.nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (widget.nextFocusNode != null) {
          widget.nextFocusNode?.requestFocus();
        } else {
          _focusNode.unfocus();
        }
      },
      decoration: InputDecoration(
        labelText: 'Player ${widget.participantNumber}',
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
    );
  }
}