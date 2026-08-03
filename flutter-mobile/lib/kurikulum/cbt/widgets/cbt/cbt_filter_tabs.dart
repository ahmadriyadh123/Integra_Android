import 'package:flutter/material.dart';

class CbtFilterTabs extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;

  const CbtFilterTabs({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0284C7);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onTabChanged(tab),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}