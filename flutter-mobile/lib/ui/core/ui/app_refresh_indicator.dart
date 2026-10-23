import 'package:flutter/material.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color color;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color = const Color(0xFF059669),
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(color: color, onRefresh: onRefresh, child: child);
  }
}
