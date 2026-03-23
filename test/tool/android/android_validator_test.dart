import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/android/android_validator.dart';
import '../../../tool/logger.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('android_validator_test_');
    logger = Logger(verbose: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('AndroidValidator', () {
    test('validates manifest with all requirements present', () {
      final manifestFile = File('${tempDir.path}/AndroidManifest.xml');
      manifestFile.writeAsStringSync('''
<manifest>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  <application>
    <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"/>
  </application>
</manifest>
''');

      final validator = AndroidValidator(logger);
      // Should not throw
      validator.validate(manifestPath: manifestFile.path);
    });

    test('warns when manifest is missing', () {
      final validator = AndroidValidator(logger);
      validator.validate(manifestPath: null);
    });

    test('validates build.gradle with correct minSdkVersion', () {
      final gradleFile = File('${tempDir.path}/build.gradle');
      gradleFile.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion 21
    }
}
apply plugin: 'com.google.gms.google-services'
''');

      final validator = AndroidValidator(logger);
      validator.validate(appBuildGradlePath: gradleFile.path);
    });

    test('warns when minSdkVersion is too low', () {
      final gradleFile = File('${tempDir.path}/build.gradle');
      gradleFile.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion 16
    }
}
''');

      final validator = AndroidValidator(logger);
      validator.validate(appBuildGradlePath: gradleFile.path);
    });

    test('warns when flutter.minSdkVersion is used', () {
      final gradleFile = File('${tempDir.path}/build.gradle');
      gradleFile.writeAsStringSync('''
android {
    defaultConfig {
        minSdkVersion flutter.minSdkVersion
    }
}
''');

      final validator = AndroidValidator(logger);
      validator.validate(appBuildGradlePath: gradleFile.path);
    });

    test('warns when build.gradle is missing', () {
      final validator = AndroidValidator(logger);
      validator.validate(appBuildGradlePath: null);
    });

    test('checks for google-services.json presence', () {
      final validator = AndroidValidator(logger);
      validator.validate(
        googleServicesJsonPath: '${tempDir.path}/google-services.json',
      );
    });

    test('warns when google-services.json is absent', () {
      final validator = AndroidValidator(logger);
      validator.validate(googleServicesJsonPath: null);
    });
  });
}
