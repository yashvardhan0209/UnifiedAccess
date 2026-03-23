import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/android/android_manifest_patcher.dart';
import '../../../tool/logger.dart';
import '../../../tool/models/setup_config.dart';
import '../../../tool/models/setup_result.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('manifest_patcher_test_');
    logger = Logger(verbose: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String _minimalManifest({
    List<String> permissions = const [],
    List<String> metaDataNames = const [],
  }) {
    final permXml = permissions
        .map((p) => '<uses-permission android:name="$p"/>')
        .join('\n');
    final metaXml = metaDataNames
        .map((n) => '<meta-data android:name="$n" android:value="$n"/>')
        .join('\n');
    return '''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
$permXml
<application android:label="Test">
$metaXml
</application>
</manifest>''';
  }

  group('AndroidManifestPatcher', () {
    test('adds all missing permissions and FCM metadata', () async {
      final manifestFile = File('${tempDir.path}/AndroidManifest.xml');
      manifestFile.writeAsStringSync(_minimalManifest());

      final patcher = AndroidManifestPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig();

      await patcher.patch(manifestFile.path, config, result);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('android.permission.INTERNET'));
      expect(content, contains('android.permission.POST_NOTIFICATIONS'));
      expect(content, contains('android.permission.VIBRATE'));
      expect(content, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(content, contains('default_notification_channel_id'));
      expect(result.changesMade, isNotEmpty);
      expect(result.backupFiles, isNotEmpty);
    });

    test('does not modify when all permissions already present', () async {
      final manifestFile = File('${tempDir.path}/AndroidManifest.xml');
      manifestFile.writeAsStringSync(
        _minimalManifest(
          permissions: [
            'android.permission.INTERNET',
            'android.permission.POST_NOTIFICATIONS',
            'android.permission.VIBRATE',
            'android.permission.RECEIVE_BOOT_COMPLETED',
          ],
          metaDataNames: [
            'com.google.firebase.messaging.default_notification_channel_id',
          ],
        ),
      );

      final patcher = AndroidManifestPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig();

      await patcher.patch(manifestFile.path, config, result);

      expect(result.changesMade, isEmpty);
      // Backup should be removed when no modifications
      expect(result.backupFiles, isEmpty);
    });

    test('adds Facebook configuration when enabled', () async {
      final manifestFile = File('${tempDir.path}/AndroidManifest.xml');
      manifestFile.writeAsStringSync(
        _minimalManifest(
          permissions: [
            'android.permission.INTERNET',
            'android.permission.POST_NOTIFICATIONS',
            'android.permission.VIBRATE',
            'android.permission.RECEIVE_BOOT_COMPLETED',
          ],
          metaDataNames: [
            'com.google.firebase.messaging.default_notification_channel_id',
          ],
        ),
      );

      final patcher = AndroidManifestPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enableFacebookLogin: true);

      await patcher.patch(manifestFile.path, config, result);

      final content = manifestFile.readAsStringSync();
      expect(content, contains('com.facebook.sdk.ApplicationId'));
      expect(content, contains('com.facebook.sdk.ClientToken'));
      expect(content, contains('com.facebook.FacebookActivity'));
      expect(content, contains('com.facebook.CustomTabActivity'));
      expect(result.changesMade, isNotEmpty);
    });

    test('skips Facebook config when already present', () async {
      final manifestFile = File('${tempDir.path}/AndroidManifest.xml');
      manifestFile.writeAsStringSync(
        _minimalManifest(
          permissions: [
            'android.permission.INTERNET',
            'android.permission.POST_NOTIFICATIONS',
            'android.permission.VIBRATE',
            'android.permission.RECEIVE_BOOT_COMPLETED',
          ],
          metaDataNames: [
            'com.google.firebase.messaging.default_notification_channel_id',
            'com.facebook.sdk.ApplicationId',
          ],
        ),
      );

      final patcher = AndroidManifestPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enableFacebookLogin: true);

      await patcher.patch(manifestFile.path, config, result);

      // No changes since facebook is already there
      expect(result.changesMade, isEmpty);
    });
  });
}
