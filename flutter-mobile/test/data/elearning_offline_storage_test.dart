import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_application_1/data/local/elearning/elearning_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Directory supportDirectory;
  late ElearningLocalStorage storage;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('elearning-hive-');
    supportDirectory = await Directory.systemTemp.createTemp(
      'elearning-support-',
    );
    Hive.init(hiveDirectory.path);
    storage = ElearningLocalStorage(
      supportDirectoryProvider: () async => supportDirectory,
    );
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
    await supportDirectory.delete(recursive: true);
  });

  test(
    'saves material files per user and removes them with the cache scope',
    () async {
      final bytes = utf8.encode('offline lesson');
      final saved = await storage.saveOfflineMaterial(
        51,
        cacheScope: 'school_4_user_10',
        fileName: '51_Materi.pdf',
        content: Stream<List<int>>.value(bytes),
      );

      expect(await saved.readAsBytes(), bytes);
      expect(
        (await storage.loadOfflineMaterial(
          51,
          cacheScope: 'school_4_user_10',
        ))?.path,
        saved.path,
      );
      expect(
        await storage.loadOfflineMaterial(51, cacheScope: 'school_4_user_11'),
        isNull,
      );

      await storage.clearAll(cacheScope: 'school_4_user_10');

      expect(await saved.exists(), isFalse);
      expect(
        await storage.loadOfflineMaterial(51, cacheScope: 'school_4_user_10'),
        isNull,
      );
    },
  );

  test(
    'rejects empty downloads and does not persist an offline file',
    () async {
      await expectLater(
        storage.saveOfflineMaterial(
          51,
          cacheScope: 'school_4_user_10',
          fileName: '51_Materi.pdf',
          content: const Stream<List<int>>.empty(),
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        await storage.loadOfflineMaterial(51, cacheScope: 'school_4_user_10'),
        isNull,
      );
    },
  );
}
