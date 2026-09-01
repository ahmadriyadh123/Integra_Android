import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DocumentUploadWidget extends StatelessWidget {
  final File? pasFotoFile;
  final File? aktaKelahiranFile;
  final File? kartuKeluargaFile;
  final File? ktpOrangTuaFile;
  final ValueChanged<File?> onPasFotoSelected;
  final ValueChanged<File?> onAktaKelahiranSelected;
  final ValueChanged<File?> onKartuKeluargaSelected;
  final ValueChanged<File?> onKtpOrangTuaSelected;

  const DocumentUploadWidget({
    super.key,
    required this.pasFotoFile,
    required this.aktaKelahiranFile,
    required this.kartuKeluargaFile,
    required this.ktpOrangTuaFile,
    required this.onPasFotoSelected,
    required this.onAktaKelahiranSelected,
    required this.onKartuKeluargaSelected,
    required this.onKtpOrangTuaSelected,
  });

  // Fungsi umum untuk memilih file berdasarkan ekstensi yang diizinkan
  Future<void> _pickFile({
    required List<String> allowedExtensions,
    required ValueChanged<File?> onFileSelected,
  }) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      onFileSelected(File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildFileField();
  }

  Widget _buildFileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unggah Dokumen Pendukung',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Pas Foto
        _buildUploadItem(
          label: 'Pas Foto (png, jpg, jpeg)',
          selectedFile: pasFotoFile,
          onTap: () {
            _pickFile(
              allowedExtensions: ['png', 'jpg', 'jpeg'],
              onFileSelected: onPasFotoSelected,
            );
          },
        ),
        const SizedBox(height: 14),

        // 2. Akta Kelahiran
        _buildUploadItem(
          label: 'Akta Kelahiran (pdf)',
          selectedFile: aktaKelahiranFile,
          onTap: () {
            _pickFile(
              allowedExtensions: ['pdf'],
              onFileSelected: onAktaKelahiranSelected,
            );
          },
        ),
        const SizedBox(height: 14),

        // 3. Kartu Keluarga
        _buildUploadItem(
          label: 'Kartu Keluarga (pdf)',
          selectedFile: kartuKeluargaFile,
          onTap: () {
            _pickFile(
              allowedExtensions: ['pdf'],
              onFileSelected: onKartuKeluargaSelected,
            );
          },
        ),
        const SizedBox(height: 14),

        // 4. KTP Orang Tua
        _buildUploadItem(
          label: 'KTP Orang Tua (pdf)',
          selectedFile: ktpOrangTuaFile,
          onTap: () {
            _pickFile(
              allowedExtensions: ['pdf'],
              onFileSelected: onKtpOrangTuaSelected,
            );
          },
        ),
      ],
    );
  }

  Widget _buildUploadItem({
    required String label,
    required File? selectedFile,
    required VoidCallback onTap,
  }) {
    final bool hasFile = selectedFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                size: 18,
              ),
              label: Text(hasFile ? 'Ganti File' : 'Pilih File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFile
                    ? Colors.teal.shade800
                    : Colors.teal.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),

            //Menampilkan nama file atau keterangan jika belum dipilih
            Expanded(
              child: Text(
                hasFile
                    ? selectedFile.path.split('/').last
                    : 'Belum ada file dipilih',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: hasFile ? Colors.black87 : Colors.grey.shade500,
                  fontStyle: hasFile ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
