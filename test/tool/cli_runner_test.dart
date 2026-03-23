import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/cli_runner.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cli_runner_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('CliRunner', () {
    test('creates with default values', () {
      final runner = CliRunner();
      expect(runner.checkOnly, isFalse);
      expect(runner.verbose, isFalse);
      expect(runner.acceptAll, isFalse);
    });

    test('creates with custom values', () {
      final runner = CliRunner(checkOnly: true, verbose: true, acceptAll: true);
      expect(runner.checkOnly, isTrue);
      expect(runner.verbose, isTrue);
      expect(runner.acceptAll, isTrue);
    });

    test('returns 1 when not a Flutter project', () async {
      final savedDir = Directory.current;
      Directory.current = tempDir;

      try {
        final runner = CliRunner(acceptAll: true);
        final exitCode = await runner.run();
        expect(exitCode, 1);
      } finally {
        Directory.current = savedDir;
      }
    });

    test('returns 1 when pubspec exists but no flutter dependency', () async {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test_project\n');

      final savedDir = Directory.current;
      Directory.current = tempDir;

      try {
        final runner = CliRunner(acceptAll: true);
        final exitCode = await runner.run();
        expect(exitCode, 1);
      } finally {
        Directory.current = savedDir;
      }
    });

    test('returns 1 when no platform directories', () async {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test\nflutter:\n  sdk: flutter\n');

      final savedDir = Directory.current;
      Directory.current = tempDir;

      try {
        final runner = CliRunner(acceptAll: true);
        final exitCode = await runner.run();
        expect(exitCode, 1);
      } finally {
        Directory.current = savedDir;
      }
    });

    test('check mode returns 0 for valid project', () async {
      _setupProjectStructure(tempDir);

      final savedDir = Directory.current;
      Directory.current = tempDir;

      try {
        final runner = CliRunner(checkOnly: true);
        final exitCode = await runner.run();
        expect(exitCode, 0);
      } finally {
        Directory.current = savedDir;
      }
    });

    test('setup mode with acceptAll returns 0', () async {
      _setupProjectStructure(tempDir);

      final savedDir = Directory.current;
      Directory.current = tempDir;

      try {
        final runner = CliRunner(acceptAll: true);
        final exitCode = await runner.run();
        expect(exitCode, 0);
      } finally {
        Directory.current = savedDir;
      }
    });

    test('setup mode with acceptAll and verbose returns 0', () async {
      _setupProjectStructure(tempDir);

      final savedDir = Directory.current;
      Directory.current = tempDir;

      try {
        final runner = CliRunner(acceptAll: true, verbose: true);
        final exitCode = await runner.run();
        expect(exitCode, 0);
      } finally {
        Directory.current = savedDir;
      }
    });
  });
}

void _setupProjectStructure(Directory root) {
  File(
    '${root.path}/pubspec.yaml',
  ).writeAsStringSync('name: test\nflutter:\n  sdk: flutter\n');

  // Android
  final manifestDir = Directory('${root.path}/android/app/src/main');
  manifestDir.createSync(recursive: true);
  File('${manifestDir.path}/AndroidManifest.xml').writeAsStringSync(
    '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
<application android:label="Test">
</application>
</manifest>''',
  );
  File('${root.path}/android/app/build.gradle').writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion 16
        targetSdkVersion 33
    }
}
''');
  File('${root.path}/android/build.gradle').writeAsStringSync('''
buildscript {
    repositories {
        google()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.0.0'
    }
}
''');

  // iOS
  final iosDir = Directory('${root.path}/ios/Runner');
  iosDir.createSync(recursive: true);
  File('${iosDir.path}/Info.plist').writeAsStringSync(
    '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>''',
  );
  File('${root.path}/ios/Podfile').writeAsStringSync("platform :ios, '11.0'\n");
}
