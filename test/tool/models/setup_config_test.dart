import 'package:flutter_test/flutter_test.dart';

import '../../../tool/models/setup_config.dart';

void main() {
  group('SetupConfig', () {
    test('creates with all defaults', () {
      final config = SetupConfig();
      expect(config.enableGoogleSignIn, isFalse);
      expect(config.enableFacebookLogin, isFalse);
      expect(config.facebookAppId, isNull);
      expect(config.facebookClientToken, isNull);
      expect(config.facebookDisplayName, isNull);
      expect(config.enableAppleSignIn, isFalse);
      expect(config.enablePushNotifications, isFalse);
    });

    test('creates with custom values', () {
      final config = SetupConfig(
        enableGoogleSignIn: true,
        enableFacebookLogin: true,
        facebookAppId: '12345',
        facebookClientToken: 'token123',
        facebookDisplayName: 'Test App',
        enableAppleSignIn: true,
        enablePushNotifications: true,
      );
      expect(config.enableGoogleSignIn, isTrue);
      expect(config.enableFacebookLogin, isTrue);
      expect(config.facebookAppId, '12345');
      expect(config.facebookClientToken, 'token123');
      expect(config.facebookDisplayName, 'Test App');
      expect(config.enableAppleSignIn, isTrue);
      expect(config.enablePushNotifications, isTrue);
    });
  });
}
