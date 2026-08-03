import 'package:flutter/material.dart';

class TokenInputBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final ValueChanged<String> onChanged;

  const TokenInputBoxes({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0284C7);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onChanged: (value) => onChanged(value),
          ),
        );
      }),
    );
  }
}