import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileDownloaderService {
  /// Menyimpan bytes PDF ke folder Download/Dokumen Lokal HP
  static Future<String> savePdfToStorage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      // 1. Minta Izin Storage untuk Android versi di bawah 13 (jika diperlukan)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          // Jika izin ditolak, coba cek permission external storage
          await Permission.manageExternalStorage.request();
        }
      }

      Directory? targetDir;

      if (Platform.isAndroid) {
        // Di Android, simpan langsung ke folder /storage/emulated/0/Download
        targetDir = Directory('/storage/emulated/0/Download/Integra');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // Di iOS, simpan ke Application Documents Directory
        targetDir = await getApplicationDocumentsDirectory();
      } else {
        targetDir = await getDownloadsDirectory();
      }

      if (targetDir == null) {
        throw Exception('Direktori penyimpanan tidak ditemukan.');
      }

      // 2. Buat Path File Tujuan
      final filePath = '${targetDir.path}/$fileName';
      final file = File(filePath);

      // 3. Tulis Bytes ke dalam File Fisik
      await file.writeAsBytes(bytes, flush: true);

      return filePath;
    } catch (e) {
      throw Exception('Gagal menyimpan file ke penyimpanan lokal: $e');
    }
  }
}