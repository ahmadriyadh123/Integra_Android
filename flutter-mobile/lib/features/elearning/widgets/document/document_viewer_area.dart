import 'package:flutter/material.dart';

class DocumentViewerArea extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double currentZoom;

  const DocumentViewerArea({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.currentZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF94A3B8), // Warna latar belakang abu-abu khas PDF Viewer
      width: double.infinity,
      height: double.infinity,
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 3.0,
        scaleEnabled: true,
        // Properti ini merepresentasikan zoom internal dari controller di masa depan
        transformationController: TransformationController(
          Matrix4.diagonal3Values(currentZoom, currentZoom, 1.0),
        ),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.65,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RANGKUMAN MATERI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Hal $currentPage',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 20),
                const Text(
                  '1. Aturan Sinus Dasar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aturan sinus (Law of Sines) adalah persamaan yang menghubungkan rasio panjang sisi-sisi segitiga dengan sinus sudut-sudut di depannya. Aturan ini sangat berguna untuk mencari panjang sisi atau besar sudut yang belum diketahui pada segitiga sembarang.\n\nDalam segitiga ABC dengan panjang sisi a, b, dan c, persamaan aturan sinus dinyatakan sebagai rasio yang proporsional.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                // Area kerangka untuk visualisasi rumus atau gambar dokumen
                const Spacer(),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}