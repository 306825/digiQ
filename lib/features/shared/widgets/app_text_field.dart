import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final bool multiline;

  const AppTextField({
    super.key,
    required this.labelText,
    required this.controller,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: multiline ? 3 : 1,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
