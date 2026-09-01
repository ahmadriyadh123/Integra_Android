import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/view/login_view.dart';
import 'auth/viewmodel/auth_viewmodel.dart';
import 'dashboard/dashboard_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State createState() => _SplashScreenState();
}

class _SplashScreenState extends State {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authViewModel = context.read<AuthViewModel>();
    final hasSession = await authViewModel.restoreSessionFromHive();

    if (!mounted) return;

    final targetPage = hasSession
        ? DashboardView(authToken: authViewModel.token)
        : const LoginView();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_icon.png',
              width: 100,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}