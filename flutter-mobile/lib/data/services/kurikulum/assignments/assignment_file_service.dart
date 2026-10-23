import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import './assignment_service.dart';

class AssignmentFileService {
  static const int maxFileSize = 20 * 1024 * 1024;

  Future<List<PlatformFile>> pickFiles() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    for (final file in files) {
      if (await file.length() > maxFileSize) {
        throw Exception('${file.name} melebihi batas ukuran 20 MiB.');
      }
    }
    return files;
  }

  Future<List<AssignmentFileUpload>> prepareUploads(
    Iterable<PlatformFile> files,
  ) async {
    final uploads = <AssignmentFileUpload>[];
    for (final file in files) {
      uploads.add(await prepareUpload(file));
    }
    return uploads;
  }

  Future<AssignmentFileUpload> prepareUpload(PlatformFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('${file.name} kosong atau tidak dapat dibaca.');
    }
    if (bytes.length > maxFileSize) {
      throw Exception('${file.name} melebihi batas ukuran 20 MiB.');
    }
    return AssignmentFileUpload(
      stream: Stream<List<int>>.value(bytes),
      size: bytes.length,
      fileName: file.name,
    );
  }
}
