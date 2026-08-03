import 'package:flutter/material.dart';

class AgendaItemCard extends StatelessWidget {
  final String dateRange;
  final String title;
  final String category;
  final String description;
  final Color accentColor;

  const AgendaItemCard({
    super.key,
    required this.dateRange,
    required this.title,
    required this.category,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);
    const Color textSlate = Color(0xFF475569);
    const Color borderSlate = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSlate),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accentColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: darkSlate,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: textSlate,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}