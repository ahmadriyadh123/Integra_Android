import 'package:flutter/material.dart';

class QuizOptionCard extends StatelessWidget {
  final String optionText;
  final String optionLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const QuizOptionCard({
    super.key,
    required this.optionText,
    required this.optionLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF059669);
    const Color primaryLightColor = Color(0xFFECFDF5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? primaryLightColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? primaryColor : const Color(0xFF334155),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}