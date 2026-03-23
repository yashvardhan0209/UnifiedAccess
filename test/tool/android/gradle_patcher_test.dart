import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/android/gradle_patcher.dart';
import '../../../tool/logger.dart';
import '../../../tool/models/setup_config.dart';
import '../../../tool/models/setup_result.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gradle_patcher_test_');
    logger = Logger(verbose: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('GradlePatcher.patchAppBuildGradle', () {
    test(
      'patches minSdkVersion, adds multiDex and google-services (Groovy)',
      () async {
        final file = File('${tempDir.path}/build.gradle');
        file.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion 16
        targetSdkVersion 33
    }
}
''');

        final patcher = GradlePatcher(logger);
        final result = SetupResult();

        await patcher.patchAppBuildGradle(file.path, SetupConfig(), result);

        final content = file.readAsStringSync();
        expect(content, contains('minSdkVersion 21'));
        expect(content, contains('multiDexEnabled true'));
        expect(
          content,
          contains("apply plugin: 'com.google.gms.google-services'"),
        );
        expect(result.changesMade, isNotEmpty);
      },
    );

    test('patches with Kotlin DSL', () async {
      final file = File('${tempDir.path}/build.gradle.kts');
      file.writeAsStringSync('''
android {
    defaultConfig {
        minSdk = 16
        targetSdk = 33
    }
}
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchAppBuildGradle(
        file.path,
        SetupConfig(),
        result,
        isKotlinDsl: true,
      );

      final content = file.readAsStringSync();
      expect(content, contains('minSdk = 21'));
      expect(content, contains('multiDexEnabled = true'));
      expect(content, contains('id("com.google.gms.google-services")'));
    });

    test('does not patch when everything is already configured', () async {
      final file = File('${tempDir.path}/build.gradle');
      file.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion 21
        multiDexEnabled true
    }
}
apply plugin: 'com.google.gms.google-services'
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchAppBuildGradle(file.path, SetupConfig(), result);

      expect(result.changesMade, isEmpty);
      expect(result.backupFiles, isEmpty);
    });

    test('does not downgrade minSdkVersion >= 21', () async {
      final file = File('${tempDir.path}/build.gradle');
      file.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion 23
        multiDexEnabled true
    }
}
apply plugin: 'com.google.gms.google-services'
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchAppBuildGradle(file.path, SetupConfig(), result);

      final content = file.readAsStringSync();
      expect(content, contains('minSdkVersion 23'));
      expect(result.changesMade, isEmpty);
    });

    test('warns when flutter.minSdkVersion is used', () async {
      final file = File('${tempDir.path}/build.gradle');
      file.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion flutter.minSdkVersion
        multiDexEnabled true
    }
}
apply plugin: 'com.google.gms.google-services'
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchAppBuildGradle(file.path, SetupConfig(), result);
      // Should not crash, should warn via logger
      expect(result.changesMade, isEmpty);
    });

    test('warns when defaultConfig block is missing for multiDex', () async {
      final file = File('${tempDir.path}/build.gradle');
      file.writeAsStringSync('''
android {
    minSdkVersion 21
}
apply plugin: 'com.google.gms.google-services'
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchAppBuildGradle(file.path, SetupConfig(), result);
      // multiDex can't be added without defaultConfig, should warn
    });
  });

  group('GradlePatcher.patchProjectBuildGradle', () {
    test('adds google-services classpath (Groovy)', () async {
      final file = File('${tempDir.path}/build.gradle');
      // Note: The regex in GradlePatcher uses [^}]* between buildscript { and
      // dependencies {, so there must be no } between them.
      file.writeAsStringSync('''
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.0.0'
    }
}
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchProjectBuildGradle(file.path, result);

      final content = file.readAsStringSync();
      expect(content, contains('com.google.gms:google-services'));
      expect(result.changesMade, isNotEmpty);
    });

    test('adds google-services classpath (Kotlin DSL)', () async {
      final file = File('${tempDir.path}/build.gradle.kts');
      file.writeAsStringSync('''
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:7.0.0")
    }
}
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchProjectBuildGradle(
        file.path,
        result,
        isKotlinDsl: true,
      );

      final content = file.readAsStringSync();
      expect(content, contains('classpath("com.google.gms:google-services'));
      expect(result.changesMade, isNotEmpty);
    });

    test('skips when classpath already present', () async {
      final file = File('${tempDir.path}/build.gradle');
      file.writeAsStringSync('''
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchProjectBuildGradle(file.path, result);

      expect(result.changesMade, isEmpty);
      expect(result.backupFiles, isEmpty);
    });

    test('warns when buildscript dependencies not found', () async {
      final file = File('${tempDir.path}/build.gradle');
      file.writeAsStringSync('''
plugins {
    id 'com.android.application'
}
''');

      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.patchProjectBuildGradle(file.path, result);

      expect(result.changesMade, isEmpty);
      expect(result.backupFiles, isEmpty);
    });
  });

  group('GradlePatcher.createStringsXml', () {
    test('creates new strings.xml with Facebook config', () async {
      final patcher = GradlePatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(
        enableFacebookLogin: true,
        facebookAppId: '123456',
        facebookClientToken: 'token789',
      );

      await patcher.createStringsXml(tempDir.path, config, result);

      final file = File(
        '${tempDir.path}/android/app/src/main/res/values/strings.xml',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('facebook_app_id'));
      expect(content, contains('123456'));
      expect(content, contains('fb123456'));
      expect(content, contains('token789'));
      expect(result.changesMade, isNotEmpty);
    });

    test('appends to existing strings.xml', () async {
      final dir = Directory('${tempDir.path}/android/app/src/main/res/values');
      dir.createSync(recursive: true);
      File('${dir.path}/strings.xml').writeAsStringSync(
        '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">Test</string>\n</resources>\n',
      );

      final patcher = GradlePatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(
        enableFacebookLogin: true,
        facebookAppId: '123456',
        facebookClientToken: 'token789',
      );

      await patcher.createStringsXml(tempDir.path, config, result);

      final content = File('${dir.path}/strings.xml').readAsStringSync();
      expect(content, contains('facebook_app_id'));
      expect(content, contains('app_name'));
    });

    test('skips when facebook_app_id already in strings.xml', () async {
      final dir = Directory('${tempDir.path}/android/app/src/main/res/values');
      dir.createSync(recursive: true);
      File('${dir.path}/strings.xml').writeAsStringSync(
        '<resources><string name="facebook_app_id">123</string></resources>',
      );

      final patcher = GradlePatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(
        enableFacebookLogin: true,
        facebookAppId: '123456',
        facebookClientToken: 'token789',
      );

      await patcher.createStringsXml(tempDir.path, config, result);

      expect(result.changesMade, isEmpty);
    });

    test('does nothing when Facebook not enabled', () async {
      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.createStringsXml(tempDir.path, SetupConfig(), result);
      expect(result.changesMade, isEmpty);
    });

    test('does nothing when facebookAppId is null', () async {
      final patcher = GradlePatcher(logger);
      final result = SetupResult();

      await patcher.createStringsXml(
        tempDir.path,
        SetupConfig(enableFacebookLogin: true),
        result,
      );
      expect(result.changesMade, isEmpty);
    });
  });
}
