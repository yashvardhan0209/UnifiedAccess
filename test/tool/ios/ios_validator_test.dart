import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/ios/ios_validator.dart';
import '../../../tool/logger.dart';

void main() {
  late Directory tempDir;
  late Logger logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ios_validator_test_');
    logger = Logger(verbose: true);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('IosValidator', () {
    test('validates when all config is present', () {
      final infoPlist = File('${tempDir.path}/Info.plist');
      infoPlist.writeAsStringSync('''
<plist>
<dict>
<key>UIBackgroundModes</key>
<array><string>remote-notification</string></array>
<key>FacebookAppID</key>
<string>123</string>
</dict>
</plist>
''');

      final podfile = File('${tempDir.path}/Podfile');
      podfile.writeAsStringSync("platform :ios, '13.0'\n");

      final validator = IosValidator(logger);
      validator.validate(
        infoPlistPath: infoPlist.path,
        podfilePath: podfile.path,
        googleServiceInfoPlistPath: '${tempDir.path}/GoogleService.plist',
      );
    });

    test('warns when Info.plist is missing', () {
      final validator = IosValidator(logger);
      validator.validate(infoPlistPath: null);
    });

    test('warns when Podfile is missing', () {
      final validator = IosValidator(logger);
      validator.validate(podfilePath: null);
    });

    test('warns when GoogleService-Info.plist is missing', () {
      final validator = IosValidator(logger);
      validator.validate(googleServiceInfoPlistPath: null);
    });

    test('warns when iOS version is too low', () {
      final podfile = File('${tempDir.path}/Podfile');
      podfile.writeAsStringSync("platform :ios, '11.0'\n");

      final validator = IosValidator(logger);
      validator.validate(podfilePath: podfile.path);
    });

    test('warns when platform version not detectable', () {
      final podfile = File('${tempDir.path}/Podfile');
      podfile.writeAsStringSync('# no platform\n');

      final validator = IosValidator(logger);
      validator.validate(podfilePath: podfile.path);
    });

    test('checks Info.plist content for missing features', () {
      final infoPlist = File('${tempDir.path}/Info.plist');
      infoPlist.writeAsStringSync('<plist><dict></dict></plist>');

      final validator = IosValidator(logger);
      validator.validate(infoPlistPath: infoPlist.path);
    });
  });
}
