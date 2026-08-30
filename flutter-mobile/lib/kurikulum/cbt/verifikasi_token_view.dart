import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodel/cbt_viewmodel.dart';
import 'widgets/token/token_info_banner.dart';
import 'widgets/token/token_input_boxes.dart';
import 'widgets/token/token_status_info.dart';
import 'cbt_exam_view.dart';
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

  void _handleTextChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  bool _isSubmitting = false;

  Future<void> _verifyToken() async {
    final tokenInput = _controllers.map((c) => c.text).join().trim();
    if (tokenInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan token ujian dari pengawas.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cbtVm = Provider.of<CbtViewModel>(context, listen: false);
      final isSuccess = await cbtVm.verifyToken(
        widget.authToken,
        widget.jadwalId,
        tokenInput,
      );

      if (mounted && isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token valid! Memulai ujian...'),
            backgroundColor: primaryColor,
            duration: Duration(seconds: 1),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CbtExamView(
              subject: widget.subject,
              jadwalId: widget.jadwalId,
              authToken: widget.authToken,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset > 0 ? bottomInset + 20 : 20),
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Silakan masukkan token akses soal dari pengawas',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
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
                  onPressed: _isSubmitting ? null : _verifyToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
      ),
    );
  }
}
