import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ios/podfile_patcher.dart';
import '../../../tool/logger.dart';
import '../../../tool/models/setup_result.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('podfile_patcher_test_');
    logger = Logger(verbose: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('PodfilePatcher', () {
    test('updates iOS version from below 13.0 to 13.0', () async {
      final file = File('${tempDir.path}/Podfile');
      file.writeAsStringSync("platform :ios, '11.0'\n");

      final patcher = PodfilePatcher(logger);
      final result = SetupResult();

      await patcher.patch(file.path, result);

      final content = file.readAsStringSync();
      expect(content, contains("platform :ios, '13.0'"));
      expect(result.changesMade, isNotEmpty);
      expect(result.backupFiles, isNotEmpty);
    });

    test('does not downgrade when version >= 13.0', () async {
      final file = File('${tempDir.path}/Podfile');
      file.writeAsStringSync("platform :ios, '14.0'\n");

      final patcher = PodfilePatcher(logger);
      final result = SetupResult();

      await patcher.patch(file.path, result);

      final content = file.readAsStringSync();
      expect(content, contains("platform :ios, '14.0'"));
      expect(result.changesMade, isEmpty);
    });

    test('warns when platform version not found in Podfile', () async {
      final file = File('${tempDir.path}/Podfile');
      file.writeAsStringSync('# no platform line\n');

      final patcher = PodfilePatcher(logger);
      final result = SetupResult();

      await patcher.patch(file.path, result);

      expect(result.changesMade, isEmpty);
    });

    test('handles version exactly 13.0', () async {
      final file = File('${tempDir.path}/Podfile');
      file.writeAsStringSync("platform :ios, '13.0'\n");

      final patcher = PodfilePatcher(logger);
      final result = SetupResult();

      await patcher.patch(file.path, result);

      expect(result.changesMade, isEmpty);
    });
  });
}
