import 'package:flutter/material.dart';
import 'widgets/token/token_info_banner.dart';
import 'widgets/token/token_input_boxes.dart';
import 'widgets/token/token_status_info.dart';
import '../../widgets/shared_header.dart';

class VerifikasiTokenView extends StatefulWidget {
  final String subject;
  final int jadwalId;
  final String authToken;

  const VerifikasiTokenView({
    super.key,
    required this.subject,
    required this.jadwalId,
    required this.authToken,
  });

  @override
  State<VerifikasiTokenView> createState() => _VerifikasiTokenViewState();
}

class _VerifikasiTokenViewState extends State<VerifikasiTokenView> {
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color primaryColor = Color(0xFF059669);
  static const Color backgroundSlate = Color(0xFFF8FAFC);

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleTextChange(String value) {
    // Logika sederhana untuk memindahkan fokus otomatis ke kotak berikutnya
    for (int i = 0; i < 6; i++) {
      if (_controllers[i].text.isNotEmpty && i < 5 && !_focusNodes[i + 1].hasFocus) {
        FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        break;
      }
    }
  }

  void _verifyToken() {
    String token = _controllers.map((c) => c.text).join();
    if (token.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan 6 digit token dengan lengkap.')),
      );
      return;
    }

    // Simulasi verifikasi token berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token $token valid! Memulai ujian...'),
        backgroundColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundSlate,
      appBar: SharedHeader(
        title: 'VERIFIKASI TOKEN UJIAN',
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        centerTitle: true,
        elevation: 0,
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              widget.subject,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Silakan masukkan token akses soal dari pengawas',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            const TokenInfoBanner(),
            const SizedBox(height: 32),
            TokenInputBoxes(
              controllers: _controllers,
              focusNodes: _focusNodes,
              onChanged: _handleTextChange,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Verifikasi & Mulai Ujian',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const TokenStatusInfo(),
          ],
        ),
      ),
    );
  }
}