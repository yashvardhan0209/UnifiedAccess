import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_access/src/unified_notification/unified_notification.dart';

// ---------- Fakes ----------

class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  final _tokenRefreshController = StreamController<String>.broadcast();
  String? token = 'test-token';
  bool requestPermissionCalled = false;
  bool setForegroundOptionsCalled = false;
  RemoteMessage? initialMessage;
  String? subscribedTopic;
  String? unsubscribedTopic;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<String?> getToken({String? vapidKey}) async => token;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    requestPermissionCalled = true;
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.enabled,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.enabled,
      criticalAlert: AppleNotificationSetting.enabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.enabled,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.enabled,
    );
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    setForegroundOptionsCalled = true;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<void> subscribeToTopic(String topic) async {
    subscribedTopic = topic;
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    unsubscribedTopic = topic;
  }

  void dispose() {
    _tokenRefreshController.close();
  }
}

class FakeAndroidFlutterLocalNotificationsPlugin extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  bool createChannelCalled = false;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    createChannelCalled = true;
  }
}

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool initializeCalled = false;
  int? cancelledId;
  bool cancelAllCalled = false;
  bool showCalled = false;
  int? shownId;
  String? shownTitle;
  String? shownBody;
  String? shownPayload;
  DidReceiveNotificationResponseCallback? notificationResponseCallback;
  FakeAndroidFlutterLocalNotificationsPlugin? androidPlugin;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    notificationResponseCallback = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
      T extends FlutterLocalNotificationsPlatform>() {
    if (androidPlugin != null && T == AndroidFlutterLocalNotificationsPlugin) {
      return androidPlugin as T;
    }
    return null;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledId = id;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    showCalled = true;
    shownId = id;
    shownTitle = title;
    shownBody = body;
    shownPayload = payload;
  }
}

class FakeDeviceInfoPlugin extends Fake implements DeviceInfoPlugin {
  AndroidDeviceInfo? fakeAndroidInfo;
  IosDeviceInfo? fakeIosInfo;

  @override
  Future<AndroidDeviceInfo> get androidInfo async => fakeAndroidInfo!;

  @override
  Future<IosDeviceInfo> get iosInfo async => fakeIosInfo!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseMessaging fakeMessaging;
  late FakeFlutterLocalNotificationsPlugin fakeLocalNotifications;
  late UnifiedNotification notificationService;

  setUp(() {
    fakeMessaging = FakeFirebaseMessaging();
    fakeLocalNotifications = FakeFlutterLocalNotificationsPlugin();
    UnifiedNotification.resetForTesting();
    UnifiedNotification.setDependenciesForTesting(
      messaging: fakeMessaging,
      localNotifications: fakeLocalNotifications,
    );
    notificationService = UnifiedNotification();
  });

  tearDown(() {
    fakeMessaging.dispose();
  });

  group('UnifiedNotification singleton', () {
    test('factory returns same instance', () {
      final a = UnifiedNotification();
      final b = UnifiedNotification();
      expect(identical(a, b), isTrue);
    });
  });

  group('onTokenRefresh', () {
    test('returns stream from FirebaseMessaging', () {
      expect(notificationService.onTokenRefresh, isA<Stream<String>>());
    });
  });

  group('subscribeToTopic', () {
    test('delegates to FirebaseMessaging', () async {
      await notificationService.subscribeToTopic('news');
      expect(fakeMessaging.subscribedTopic, 'news');
    });
  });

  group('unsubscribeFromTopic', () {
    test('delegates to FirebaseMessaging', () async {
      await notificationService.unsubscribeFromTopic('news');
      expect(fakeMessaging.unsubscribedTopic, 'news');
    });
  });

  group('cancelNotification', () {
    test('delegates to FlutterLocalNotificationsPlugin', () async {
      await notificationService.cancelNotification(42);
      expect(fakeLocalNotifications.cancelledId, 42);
    });
  });

  group('cancelAllNotifications', () {
    test('delegates to FlutterLocalNotificationsPlugin', () async {
      await notificationService.cancelAllNotifications();
      expect(fakeLocalNotifications.cancelAllCalled, isTrue);
    });
  });

  group('handleBackgroundMessage', () {
    test('does not call callback when not initialized', () async {
      UnifiedNotification.resetForTesting();

      const message = RemoteMessage(messageId: 'msg1');
      await UnifiedNotification.handleBackgroundMessage(message);
    });

    test('calls callback when initialized', () async {
      RemoteMessage? receivedMessage;

      await notificationService.init(
        onOpenNotification: (msg) => receivedMessage = msg,
        defaultIcon: 'test_icon',
      );

      const message = RemoteMessage(messageId: 'msg2');
      await UnifiedNotification.handleBackgroundMessage(message);

      expect(receivedMessage, message);
    });
  });

  group('init', () {
    test('initializes without cloud messaging', () async {
      final result = await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'test_icon',
      );

      expect(result, isNull);
      expect(fakeLocalNotifications.initializeCalled, isTrue);
      expect(fakeMessaging.requestPermissionCalled, isFalse);
    });

    test('initializes with cloud messaging', () async {
      final onMessageController = StreamController<RemoteMessage>.broadcast();
      final onMessageOpenedAppController =
          StreamController<RemoteMessage>.broadcast();
      bool backgroundMessageHandlerSet = false;

      UnifiedNotification.setDependenciesForTesting(
        onMessageStream: () => onMessageController.stream,
        onMessageOpenedAppStream: () => onMessageOpenedAppController.stream,
        onBackgroundMessage: (_) {
          backgroundMessageHandlerSet = true;
        },
      );

      final result = await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'test_icon',
        enableCloudMessaging: true,
      );

      expect(result, isNotNull);
      expect(result!.authorizationStatus, AuthorizationStatus.authorized);
      expect(fakeMessaging.requestPermissionCalled, isTrue);
      expect(fakeMessaging.setForegroundOptionsCalled, isTrue);
      expect(backgroundMessageHandlerSet, isTrue);

      await onMessageController.close();
      await onMessageOpenedAppController.close();
    });

    test('uses custom channel parameters', () async {
      await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'custom_icon',
        channelId: 'custom_channel',
        channelName: 'Custom Channel',
        channelDescription: 'Custom description',
        importance: Importance.high,
      );

      expect(fakeLocalNotifications.initializeCalled, isTrue);
    });

    test('creates Android notification channel when platform is available',
        () async {
      final fakeAndroid = FakeAndroidFlutterLocalNotificationsPlugin();
      fakeLocalNotifications.androidPlugin = fakeAndroid;

      await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'test_icon',
      );

      expect(fakeAndroid.createChannelCalled, isTrue);
    });

    test('processes initial message from getInitialMessage', () async {
      fakeMessaging.initialMessage = const RemoteMessage(
        messageId: 'initial-msg',
        notification: RemoteNotification(title: 'Init Title', body: 'Init Body'),
      );

      final onMessageController = StreamController<RemoteMessage>.broadcast();
      final onMessageOpenedAppController =
          StreamController<RemoteMessage>.broadcast();

      UnifiedNotification.setDependenciesForTesting(
        onMessageStream: () => onMessageController.stream,
        onMessageOpenedAppStream: () => onMessageOpenedAppController.stream,
        onBackgroundMessage: (_) {},
      );

      await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'test_icon',
        enableCloudMessaging: true,
      );

      // The initial message should have triggered _handleMessage which calls show
      expect(fakeLocalNotifications.showCalled, isTrue);
      expect(fakeLocalNotifications.shownTitle, 'Init Title');
      expect(fakeLocalNotifications.shownBody, 'Init Body');

      await onMessageController.close();
      await onMessageOpenedAppController.close();
    });
  });

  group('_handleMessage', () {
    late StreamController<RemoteMessage> onMessageController;

    setUp(() async {
      onMessageController = StreamController<RemoteMessage>.broadcast();

      UnifiedNotification.setDependenciesForTesting(
        onMessageStream: () => onMessageController.stream,
        onMessageOpenedAppStream:
            () => StreamController<RemoteMessage>.broadcast().stream,
        onBackgroundMessage: (_) {},
      );

      await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'test_icon',
        enableCloudMessaging: true,
      );

      // Reset show state from init
      fakeLocalNotifications.showCalled = false;
    });

    test('shows local notification for foreground message', () async {
      const message = RemoteMessage(
        messageId: 'fg-msg',
        notification: RemoteNotification(title: 'FG Title', body: 'FG Body'),
      );

      onMessageController.add(message);
      // Allow stream listener to process
      await Future<void>.delayed(Duration.zero);

      expect(fakeLocalNotifications.showCalled, isTrue);
      expect(fakeLocalNotifications.shownTitle, 'FG Title');
      expect(fakeLocalNotifications.shownBody, 'FG Body');
      expect(fakeLocalNotifications.shownPayload, isNotNull);

      await onMessageController.close();
    });

    test('ignores message without notification', () async {
      const message = RemoteMessage(messageId: 'data-only');

      onMessageController.add(message);
      await Future<void>.delayed(Duration.zero);

      expect(fakeLocalNotifications.showCalled, isFalse);

      await onMessageController.close();
    });
  });

  group('_handleNotificationOpen', () {
    test('calls onOpenNotification callback', () async {
      RemoteMessage? receivedMessage;

      final onMessageOpenedAppController =
          StreamController<RemoteMessage>.broadcast();

      UnifiedNotification.setDependenciesForTesting(
        onMessageStream:
            () => StreamController<RemoteMessage>.broadcast().stream,
        onMessageOpenedAppStream: () => onMessageOpenedAppController.stream,
        onBackgroundMessage: (_) {},
      );

      await notificationService.init(
        onOpenNotification: (msg) => receivedMessage = msg,
        defaultIcon: 'test_icon',
        enableCloudMessaging: true,
      );

      const message = RemoteMessage(messageId: 'opened-msg');
      onMessageOpenedAppController.add(message);
      await Future<void>.delayed(Duration.zero);

      expect(receivedMessage, message);

      await onMessageOpenedAppController.close();
    });
  });

  group('notification response callback', () {
    test('invokes onOpenNotification with parsed payload', () async {
      RemoteMessage? receivedMessage;

      await notificationService.init(
        onOpenNotification: (msg) => receivedMessage = msg,
        defaultIcon: 'test_icon',
      );

      // Create a valid RemoteMessage map payload
      const testMessage = RemoteMessage(messageId: 'payload-msg');
      final payload = jsonEncode(testMessage.toMap());

      // Simulate a notification response with the payload
      fakeLocalNotifications.notificationResponseCallback?.call(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: payload,
        ),
      );

      expect(receivedMessage, isNotNull);
    });

    test('invokes onOpenNotification with null for empty payload', () async {
      bool callbackCalled = false;

      await notificationService.init(
        onOpenNotification: (msg) => callbackCalled = true,
        defaultIcon: 'test_icon',
      );

      // Simulate empty payload
      fakeLocalNotifications.notificationResponseCallback?.call(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '',
        ),
      );

      expect(callbackCalled, isFalse);
    });

    test('invokes onOpenNotification with null for null payload', () async {
      bool callbackCalled = false;

      await notificationService.init(
        onOpenNotification: (msg) => callbackCalled = true,
        defaultIcon: 'test_icon',
      );

      // Simulate null payload
      fakeLocalNotifications.notificationResponseCallback?.call(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ),
      );

      expect(callbackCalled, isFalse);
    });

    test('invokes onOpenNotification with null for malformed payload', () async {
      RemoteMessage? receivedMessage;
      bool callbackCalled = false;

      await notificationService.init(
        onOpenNotification: (msg) {
          callbackCalled = true;
          receivedMessage = msg;
        },
        defaultIcon: 'test_icon',
      );

      // Simulate malformed JSON payload
      fakeLocalNotifications.notificationResponseCallback?.call(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'not-valid-json',
        ),
      );

      expect(callbackCalled, isTrue);
      expect(receivedMessage, isNull);
    });
  });

  group('getFcmToken', () {
    test('returns token with Android device info', () async {
      final fakeDeviceInfo = FakeDeviceInfoPlugin();
      fakeDeviceInfo.fakeAndroidInfo = AndroidDeviceInfo.fromMap({
        'id': 'test-id',
        'version': {
          'baseOS': '',
          'codename': '',
          'incremental': '',
          'previewSdkInt': 0,
          'release': '14',
          'sdkInt': 34,
          'securityPatch': '',
          'mediaPerformanceClass': 0,
        },
        'board': '',
        'bootloader': '',
        'brand': 'test',
        'device': 'test',
        'display': '',
        'fingerprint': '',
        'hardware': '',
        'host': '',
        'manufacturer': 'test',
        'model': 'test',
        'product': '',
        'supported32BitAbis': <String>[],
        'supported64BitAbis': <String>[],
        'supportedAbis': <String>[],
        'tags': '',
        'type': '',
        'isPhysicalDevice': false,
        'systemFeatures': <String>[],
        'serialNumber': '',
        'isLowRamDevice': false,
        'freeDiskSize': 0,
        'totalDiskSize': 0,
        'physicalRamSize': 0,
        'availableRamSize': 0,
      });

      UnifiedNotification.setDependenciesForTesting(
        deviceInfoFactory: () => fakeDeviceInfo,
        isAndroid: () => true,
        isIOS: () => false,
      );

      final result = await notificationService.getFcmToken();

      expect(result, isNotNull);
      expect(result!.fcmToken, 'test-token');
      expect(result.androidDeviceInfo, isNotNull);
    });

    test('returns token with iOS device info', () async {
      final fakeDeviceInfo = FakeDeviceInfoPlugin();
      fakeDeviceInfo.fakeIosInfo = IosDeviceInfo.fromMap({
        'name': 'iPhone',
        'systemName': 'iOS',
        'systemVersion': '17.0',
        'model': 'iPhone',
        'modelName': 'iPhone 15',
        'localizedModel': 'iPhone',
        'identifierForVendor': 'test-uuid',
        'isPhysicalDevice': false,
        'isiOSAppOnMac': false,
        'freeDiskSize': 0,
        'totalDiskSize': 0,
        'physicalRamSize': 0,
        'availableRamSize': 0,
        'utsname': {
          'sysname': 'Darwin',
          'nodename': 'test',
          'release': '23.0',
          'version': 'test',
          'machine': 'iPhone15,2',
        },
      });

      UnifiedNotification.setDependenciesForTesting(
        deviceInfoFactory: () => fakeDeviceInfo,
        isAndroid: () => false,
        isIOS: () => true,
      );

      final result = await notificationService.getFcmToken();

      expect(result, isNotNull);
      expect(result!.fcmToken, 'test-token');
      expect(result.iosDeviceInfo, isNotNull);
    });

    test('returns token without device info on unknown platform', () async {
      UnifiedNotification.setDependenciesForTesting(
        isAndroid: () => false,
        isIOS: () => false,
      );

      final result = await notificationService.getFcmToken();

      expect(result, isNotNull);
      expect(result!.fcmToken, 'test-token');
      expect(result.androidDeviceInfo, isNull);
      expect(result.iosDeviceInfo, isNull);
    });

    test('returns empty token when getToken returns null', () async {
      fakeMessaging.token = null;

      UnifiedNotification.setDependenciesForTesting(
        isAndroid: () => false,
        isIOS: () => false,
      );

      final result = await notificationService.getFcmToken();

      expect(result, isNotNull);
      expect(result!.fcmToken, '');
    });
  });

  group('showNotification', () {
    setUp(() async {
      await notificationService.init(
        onOpenNotification: (_) {},
        defaultIcon: 'test_icon',
      );
      // Reset so we can check show was called
      fakeLocalNotifications.showCalled = false;
    });

    test('shows notification with provided id', () async {
      await notificationService.showNotification(
        id: 5,
        title: 'Test Title',
        body: 'Test Body',
      );

      expect(fakeLocalNotifications.showCalled, isTrue);
      expect(fakeLocalNotifications.shownId, 5);
      expect(fakeLocalNotifications.shownTitle, 'Test Title');
      expect(fakeLocalNotifications.shownBody, 'Test Body');
    });

    test('shows notification with null id uses 0', () async {
      await notificationService.showNotification(
        id: null,
        title: 'Test Title',
        body: 'Test Body',
      );

      expect(fakeLocalNotifications.shownId, 0);
    });
  });
}
