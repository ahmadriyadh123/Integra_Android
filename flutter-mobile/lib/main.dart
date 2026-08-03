import 'package:flutter/material.dart';
import 'dashboard/dashboard_view.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Odoo Connection Test',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const DashboardScreen(studentName: 'John Doe', studentClass: '12A'),
    );
  }
}
