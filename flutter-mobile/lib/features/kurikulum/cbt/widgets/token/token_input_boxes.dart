import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TokenInputBoxes extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;

  const TokenInputBoxes({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  static const Color primaryColor = Color(0xFF059669);
  static const Color darkSlate = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        controllers.length,
        (index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index == controllers.length - 1 ? 0 : 8,
            ),
            child: SizedBox(
              width: 44,
              height: 52,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],

                maxLength: 1,

                // Keyboard alfabet + angka, bukan numeric-only
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,

                textCapitalization: TextCapitalization.characters,

                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.0,
                ),

                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9]'),
                  ),
                  UpperCaseTextFormatter(),
                ],

                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 2,
                    ),
                  ),
                ),

                onChanged: (value) {
                  onChanged(index, value);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}