import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ios/info_plist_patcher.dart';
import '../../../tool/logger.dart';
import '../../../tool/models/setup_config.dart';
import '../../../tool/models/setup_result.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('info_plist_patcher_test_');
    logger = Logger(verbose: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  String _minimalPlist({String inner = ''}) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
$inner
</dict>
</plist>''';
  }

  group('InfoPlistPatcher', () {
    test('adds UIBackgroundModes for push notifications', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(_minimalPlist());

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enablePushNotifications: true);

      await patcher.patch(file.path, config, result);

      final content = file.readAsStringSync();
      expect(content, contains('UIBackgroundModes'));
      expect(content, contains('remote-notification'));
      expect(content, contains('fetch'));
      expect(result.changesMade, isNotEmpty);
    });

    test('adds remote-notification to existing UIBackgroundModes', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(
        _minimalPlist(
          inner: '''
<key>UIBackgroundModes</key>
<array>
<string>audio</string>
</array>
''',
        ),
      );

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enablePushNotifications: true);

      await patcher.patch(file.path, config, result);

      final content = file.readAsStringSync();
      expect(content, contains('remote-notification'));
      expect(content, contains('fetch'));
      expect(content, contains('audio'));
    });

    test('skips UIBackgroundModes if already fully configured', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(
        _minimalPlist(
          inner: '''
<key>UIBackgroundModes</key>
<array>
<string>remote-notification</string>
<string>fetch</string>
</array>
''',
        ),
      );

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enablePushNotifications: true);

      await patcher.patch(file.path, config, result);

      expect(result.changesMade, isEmpty);
    });

    test('adds Facebook config when enabled', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(_minimalPlist());

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(
        enableFacebookLogin: true,
        facebookAppId: '123456',
        facebookClientToken: 'token789',
        facebookDisplayName: 'Test App',
      );

      await patcher.patch(file.path, config, result);

      final content = file.readAsStringSync();
      expect(content, contains('FacebookAppID'));
      expect(content, contains('123456'));
      expect(content, contains('FacebookClientToken'));
      expect(content, contains('FacebookDisplayName'));
      expect(content, contains('fb123456'));
      expect(content, contains('LSApplicationQueriesSchemes'));
      expect(content, contains('fbapi'));
      expect(result.changesMade, isNotEmpty);
    });

    test('skips Facebook config when already present', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(
        _minimalPlist(
          inner: '''
<key>FacebookAppID</key>
<string>123456</string>
''',
        ),
      );

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(
        enableFacebookLogin: true,
        facebookAppId: '123456',
      );

      await patcher.patch(file.path, config, result);

      expect(result.changesMade, isEmpty);
    });

    test(
      'adds Google Sign-In URL scheme from GoogleService-Info.plist',
      () async {
        // Create GoogleService-Info.plist with REVERSED_CLIENT_ID
        final googlePlist = File('${tempDir.path}/GoogleService-Info.plist');
        googlePlist.writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.123456</string>
</dict>
</plist>''');

        final file = File('${tempDir.path}/Info.plist');
        file.writeAsStringSync(_minimalPlist());

        final patcher = InfoPlistPatcher(logger);
        final result = SetupResult();
        final config = SetupConfig(enableGoogleSignIn: true);

        await patcher.patch(
          file.path,
          config,
          result,
          googleServiceInfoPlistPath: googlePlist.path,
        );

        final content = file.readAsStringSync();
        expect(content, contains('com.googleusercontent.apps.123456'));
        expect(content, contains('CFBundleURLSchemes'));
      },
    );

    test('warns when GoogleService-Info.plist is missing', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(_minimalPlist());

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enableGoogleSignIn: true);

      await patcher.patch(file.path, config, result);

      expect(result.manualSteps, isNotEmpty);
    });

    test('skips Google URL scheme if already present', () async {
      final googlePlist = File('${tempDir.path}/GoogleService-Info.plist');
      googlePlist.writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.123456</string>
</dict>
</plist>''');

      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(
        _minimalPlist(
          inner: '''
<key>CFBundleURLTypes</key>
<array>
<dict>
<key>CFBundleURLSchemes</key>
<array>
<string>com.googleusercontent.apps.123456</string>
</array>
</dict>
</array>
''',
        ),
      );

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enableGoogleSignIn: true);

      await patcher.patch(
        file.path,
        config,
        result,
        googleServiceInfoPlistPath: googlePlist.path,
      );

      expect(result.changesMade, isEmpty);
    });

    test('no changes when config has nothing enabled', () async {
      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(_minimalPlist());

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig();

      await patcher.patch(file.path, config, result);

      expect(result.changesMade, isEmpty);
      expect(result.backupFiles, isEmpty);
    });

    test('handles malformed GoogleService-Info.plist gracefully', () async {
      final googlePlist = File('${tempDir.path}/GoogleService-Info.plist');
      googlePlist.writeAsStringSync('not xml');

      final file = File('${tempDir.path}/Info.plist');
      file.writeAsStringSync(_minimalPlist());

      final patcher = InfoPlistPatcher(logger);
      final result = SetupResult();
      final config = SetupConfig(enableGoogleSignIn: true);

      await patcher.patch(
        file.path,
        config,
        result,
        googleServiceInfoPlistPath: googlePlist.path,
      );

      // Should fall through to warning path
      expect(result.manualSteps, isNotEmpty);
    });
  });
}
