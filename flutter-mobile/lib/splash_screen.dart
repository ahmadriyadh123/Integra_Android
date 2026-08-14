import 'package:flutter/material.dart';
import 'auth/view/login_view.dart'; // Ganti dengan halaman utama Anda

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

  void _navigateToHome() async {
    // Durasi tampilnya splash screen custom (misal 2 detik)
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Pindah ke halaman utama
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
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
            // Bebas mengatur ukuran logo tanpa batasan circle mask
            Image.asset(
              'assets/logo_integra.png',
              width: 100, // Bebas atur ukuran piksel
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