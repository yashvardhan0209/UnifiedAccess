import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/project_detector.dart';

void main() {
  group('ProjectPaths', () {
    test('hasAndroid is true when androidManifest is set', () {
      final paths = ProjectPaths(
        root: '/test',
        androidManifest: '/test/android/app/src/main/AndroidManifest.xml',
      );
      expect(paths.hasAndroid, isTrue);
    });

    test('hasAndroid is false when androidManifest is null', () {
      final paths = ProjectPaths(root: '/test');
      expect(paths.hasAndroid, isFalse);
    });

    test('hasIos is true when iosInfoPlist is set', () {
      final paths = ProjectPaths(
        root: '/test',
        iosInfoPlist: '/test/ios/Runner/Info.plist',
      );
      expect(paths.hasIos, isTrue);
    });

    test('hasIos is false when iosInfoPlist is null', () {
      final paths = ProjectPaths(root: '/test');
      expect(paths.hasIos, isFalse);
    });

    test('isKotlinDsl defaults to false', () {
      final paths = ProjectPaths(root: '/test');
      expect(paths.isKotlinDsl, isFalse);
    });

    test('stores all path fields', () {
      final paths = ProjectPaths(
        root: '/test',
        androidManifest: '/m',
        androidAppBuildGradle: '/ag',
        androidProjectBuildGradle: '/pg',
        iosInfoPlist: '/ip',
        iosPodfile: '/pod',
        iosGoogleServiceInfoPlist: '/gsi',
        androidGoogleServicesJson: '/gsj',
        androidStringsXml: '/str',
        isKotlinDsl: true,
      );
      expect(paths.root, '/test');
      expect(paths.androidManifest, '/m');
      expect(paths.androidAppBuildGradle, '/ag');
      expect(paths.androidProjectBuildGradle, '/pg');
      expect(paths.iosInfoPlist, '/ip');
      expect(paths.iosPodfile, '/pod');
      expect(paths.iosGoogleServiceInfoPlist, '/gsi');
      expect(paths.androidGoogleServicesJson, '/gsj');
      expect(paths.androidStringsXml, '/str');
      expect(paths.isKotlinDsl, isTrue);
    });
  });

  group('ProjectDetector', () {
    late Directory tempDir;
    late ProjectDetector detector;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('project_detector_test_');
      detector = ProjectDetector();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('returns null when pubspec.yaml does not exist', () {
      expect(detector.detect(tempDir.path), isNull);
    });

    test('returns null when pubspec.yaml does not contain flutter:', () {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test_project\n');
      expect(detector.detect(tempDir.path), isNull);
    });

    test('detects Flutter project with Groovy gradle', () {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test_project\nflutter:\n  sdk: flutter\n');

      // Create Android structure
      final manifestDir = Directory('${tempDir.path}/android/app/src/main');
      manifestDir.createSync(recursive: true);
      File(
        '${manifestDir.path}/AndroidManifest.xml',
      ).writeAsStringSync('<manifest/>');
      File('${tempDir.path}/android/app/build.gradle').writeAsStringSync('');
      File('${tempDir.path}/android/build.gradle').writeAsStringSync('');

      // Create iOS structure
      final iosDir = Directory('${tempDir.path}/ios/Runner');
      iosDir.createSync(recursive: true);
      File('${iosDir.path}/Info.plist').writeAsStringSync('<plist/>');
      File('${tempDir.path}/ios/Podfile').writeAsStringSync('');

      final paths = detector.detect(tempDir.path);
      expect(paths, isNotNull);
      expect(paths!.root, tempDir.path);
      expect(paths.hasAndroid, isTrue);
      expect(paths.hasIos, isTrue);
      expect(paths.isKotlinDsl, isFalse);
      expect(paths.androidManifest, isNotNull);
      expect(paths.androidAppBuildGradle, isNotNull);
      expect(paths.androidProjectBuildGradle, isNotNull);
      expect(paths.iosInfoPlist, isNotNull);
      expect(paths.iosPodfile, isNotNull);
    });

    test('detects Kotlin DSL gradle', () {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test\nflutter:\n');

      final manifestDir = Directory('${tempDir.path}/android/app/src/main');
      manifestDir.createSync(recursive: true);
      File(
        '${manifestDir.path}/AndroidManifest.xml',
      ).writeAsStringSync('<manifest/>');
      File(
        '${tempDir.path}/android/app/build.gradle.kts',
      ).writeAsStringSync('');
      File('${tempDir.path}/android/build.gradle.kts').writeAsStringSync('');

      final paths = detector.detect(tempDir.path);
      expect(paths, isNotNull);
      expect(paths!.isKotlinDsl, isTrue);
      expect(paths.androidAppBuildGradle, isNotNull);
      expect(paths.androidProjectBuildGradle, isNotNull);
    });

    test('detects missing google-services files', () {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test\nflutter:\n');

      final paths = detector.detect(tempDir.path);
      expect(paths, isNotNull);
      expect(paths!.androidGoogleServicesJson, isNull);
      expect(paths.iosGoogleServiceInfoPlist, isNull);
    });

    test('detects present google-services files', () {
      File(
        '${tempDir.path}/pubspec.yaml',
      ).writeAsStringSync('name: test\nflutter:\n');

      final androidAppDir = Directory('${tempDir.path}/android/app');
      androidAppDir.createSync(recursive: true);
      File(
        '${androidAppDir.path}/google-services.json',
      ).writeAsStringSync('{}');

      final iosRunnerDir = Directory('${tempDir.path}/ios/Runner');
      iosRunnerDir.createSync(recursive: true);
      File(
        '${iosRunnerDir.path}/GoogleService-Info.plist',
      ).writeAsStringSync('<plist/>');

      final paths = detector.detect(tempDir.path);
      expect(paths!.androidGoogleServicesJson, isNotNull);
      expect(paths.iosGoogleServiceInfoPlist, isNotNull);
    });
  });
}
