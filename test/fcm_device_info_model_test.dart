import 'package:flutter_test/flutter_test.dart';
import 'package:unified_access/src/unified_notification/model/fcm_device_info/fcm_device_info_model.dart';

void main() {
  group('FcmDeviceInfoModel', () {
    test('creates with required fcmToken', () {
      final model = FcmDeviceInfoModel(fcmToken: 'test-token');
      expect(model.fcmToken, 'test-token');
      expect(model.androidDeviceInfo, isNull);
      expect(model.iosDeviceInfo, isNull);
    });

    test('creates with explicit null device info', () {
      final model = FcmDeviceInfoModel(
        fcmToken: 'token',
        androidDeviceInfo: null,
        iosDeviceInfo: null,
      );
      expect(model.fcmToken, 'token');
      expect(model.androidDeviceInfo, isNull);
      expect(model.iosDeviceInfo, isNull);
    });

    test('equality works for identical values', () {
      final a = FcmDeviceInfoModel(fcmToken: 'token');
      final b = FcmDeviceInfoModel(fcmToken: 'token');
      expect(a, equals(b));
    });

    test('inequality for different fcmToken', () {
      final a = FcmDeviceInfoModel(fcmToken: 'token1');
      final b = FcmDeviceInfoModel(fcmToken: 'token2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal instances', () {
      final a = FcmDeviceInfoModel(fcmToken: 'token');
      final b = FcmDeviceInfoModel(fcmToken: 'token');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns readable representation', () {
      final model = FcmDeviceInfoModel(fcmToken: 'test-token');
      expect(model.toString(), contains('FcmDeviceInfoModel'));
      expect(model.toString(), contains('test-token'));
    });

    test('copyWith creates new instance with changed fields', () {
      final original = FcmDeviceInfoModel(fcmToken: 'original');
      final copied = original.copyWith(fcmToken: 'copied');
      expect(copied.fcmToken, 'copied');
      expect(original.fcmToken, 'original');
    });

    test('copyWith without args returns equal instance', () {
      final original = FcmDeviceInfoModel(fcmToken: 'token');
      final copied = original.copyWith();
      expect(copied, equals(original));
    });
  });
}
