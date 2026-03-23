// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unified_access/src/unified_notification/model/fcm_device_info/fcm_device_info_model.dart';

/// Callback type for notification open events that provides the [RemoteMessage] data.
typedef NotificationOpenedCallback = void Function(RemoteMessage? message);

/// UnifiedNotification class
///
/// Manages notification services, including local notifications and Firebase Cloud Messaging (FCM).
/// Provides methods for initializing notifications, retrieving the FCM token, and handling
/// notification interactions, including click events with custom logic.
class UnifiedNotification {
  /// Singleton instance of UnifiedNotification
  factory UnifiedNotification() {
    return _firebaseNotificationService;
  }

  UnifiedNotification._internal();

  static final UnifiedNotification _firebaseNotificationService =
      UnifiedNotification._internal();

  /// Callback when a notification is clicked. Receives the notification data
  /// so consumers can route to specific screens based on payload.
  NotificationOpenedCallback? _onOpenNotification;

  /// Default icon for Android notifications.
  String? _defaultIcon;

  bool _isInitialized = false;

  // coverage:ignore-start
  late FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Injectable wrappers for static FirebaseMessaging streams/methods.
  Stream<RemoteMessage> Function() _onMessageStream =
      () => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> Function() _onMessageOpenedAppStream =
      () => FirebaseMessaging.onMessageOpenedApp;
  void Function(Future<void> Function(RemoteMessage)) _onBackgroundMessage =
      FirebaseMessaging.onBackgroundMessage;

  // Injectable wrapper for DeviceInfoPlugin.
  DeviceInfoPlugin Function() _deviceInfoFactory = () => DeviceInfoPlugin();

  // Injectable wrapper for Platform checks.
  bool Function() _isAndroid = () => Platform.isAndroid;
  bool Function() _isIOS = () => Platform.isIOS;
  // coverage:ignore-end

  /// Overrides dependencies for testing.
  @visibleForTesting
  static void setDependenciesForTesting({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    Stream<RemoteMessage> Function()? onMessageStream,
    Stream<RemoteMessage> Function()? onMessageOpenedAppStream,
    void Function(Future<void> Function(RemoteMessage))? onBackgroundMessage,
    DeviceInfoPlugin Function()? deviceInfoFactory,
    bool Function()? isAndroid,
    bool Function()? isIOS,
  }) {
    if (messaging != null) {
      _firebaseNotificationService._firebaseMessaging = messaging;
    }
    if (localNotifications != null) {
      _firebaseNotificationService._flutterLocalNotificationsPlugin =
          localNotifications;
    }
    if (onMessageStream != null) {
      _firebaseNotificationService._onMessageStream = onMessageStream;
    }
    if (onMessageOpenedAppStream != null) {
      _firebaseNotificationService._onMessageOpenedAppStream =
          onMessageOpenedAppStream;
    }
    if (onBackgroundMessage != null) {
      _firebaseNotificationService._onBackgroundMessage = onBackgroundMessage;
    }
    if (deviceInfoFactory != null) {
      _firebaseNotificationService._deviceInfoFactory = deviceInfoFactory;
    }
    if (isAndroid != null) {
      _firebaseNotificationService._isAndroid = isAndroid;
    }
    if (isIOS != null) {
      _firebaseNotificationService._isIOS = isIOS;
    }
  }

  /// Resets the initialized state for testing.
  @visibleForTesting
  static void resetForTesting() {
    _firebaseNotificationService._isInitialized = false;
    _firebaseNotificationService._onOpenNotification = null;
    _firebaseNotificationService._defaultIcon = null;
  }

  /// Android notification channel for notifications.
  late AndroidNotificationChannel _androidChannel;

  /// Stream of FCM token refreshes. Listen to this to update your backend
  /// when the device token changes.
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  /// Retrieves FCM token and device information.
  Future<FcmDeviceInfoModel?> getFcmToken() async {
    final fcmToken = await _firebaseMessaging.getToken() ?? '';

    if (_isAndroid()) {
      final deviceInfo = await _deviceInfoFactory().androidInfo;
      return FcmDeviceInfoModel(
        fcmToken: fcmToken,
        androidDeviceInfo: deviceInfo,
      );
    } else if (_isIOS()) {
      final deviceInfo = await _deviceInfoFactory().iosInfo;
      return FcmDeviceInfoModel(fcmToken: fcmToken, iosDeviceInfo: deviceInfo);
    } else {
      return FcmDeviceInfoModel(fcmToken: fcmToken);
    }
  }

  /// Initializes notification services, setting up local notifications and optionally enabling Firebase Cloud Messaging (FCM).
  ///
  /// [onOpenNotification] Callback triggered when a notification is clicked, receives the [RemoteMessage] data.
  /// [defaultIcon] Default icon resource name for Android notifications.
  /// [enableCloudMessaging] Enables Firebase Cloud Messaging if true.
  /// [channelId] Custom Android notification channel ID (defaults to FCM default channel).
  /// [channelName] Custom Android notification channel name (defaults to 'high_importance_channel').
  /// [channelDescription] Custom channel description.
  /// [importance] Notification importance level (defaults to [Importance.max]).
  ///
  /// Returns [NotificationSettings] if cloud messaging is enabled, null otherwise.
  Future<NotificationSettings?> init({
    required NotificationOpenedCallback onOpenNotification,
    required String defaultIcon,
    bool enableCloudMessaging = false,
    String channelId =
        'com.google.firebase.messaging.default_notification_channel_id',
    String channelName = 'high_importance_channel',
    String channelDescription =
        'This Channel is used for important notifications.',
    Importance importance = Importance.max,
  }) async {
    _defaultIcon = defaultIcon;
    _onOpenNotification = onOpenNotification;

    _androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: importance,
    );

    await _initLocalNotification();

    NotificationSettings? settings;
    if (enableCloudMessaging) {
      settings = await _firebaseMessaging.requestPermission();
      await _initFirebaseCloudMessaging();
    }

    _isInitialized = true;
    return settings;
  }

  /// Subscribe to a FCM topic for receiving targeted push notifications.
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// Cancel a specific notification by its [id].
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  /// Cancel all active notifications.
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Initializes Firebase Cloud Messaging (FCM) to handle notifications in various states.
  Future<void> _initFirebaseCloudMessaging() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _firebaseMessaging.getInitialMessage().then(_handleMessage);

    _onMessageOpenedAppStream().listen(_handleNotificationOpen);
    _onBackgroundMessage(handleBackgroundMessage);
    _onMessageStream().listen(_handleMessage);
  }

  /// Initializes local notification settings for both Android and iOS.
  Future<void> _initLocalNotification() async {
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings(
        _defaultIcon ?? '@mipmap/ic_launcher',
      ),
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null || details.payload!.isEmpty) return;
        try {
          final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
          _onOpenNotification?.call(message);
        } catch (_) {
          // Malformed payload — invoke callback with null
          _onOpenNotification?.call(null);
        }
      },
    );

    final platform = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await platform?.createNotificationChannel(_androidChannel);
  }

  /// Handles notification taps from background/terminated state.
  void _handleNotificationOpen(RemoteMessage message) {
    _onOpenNotification?.call(message);
  }

  /// Handles background messages. This must be a static/top-level function.
  /// In background isolates, the singleton is uninitialized so we guard
  /// against accessing late fields.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (_firebaseNotificationService._isInitialized) {
      _firebaseNotificationService._onOpenNotification?.call(message);
    }
  }

  /// Handles incoming Firebase messages and displays them as local notifications.
  Future<void> _handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    final notification = message.notification;
    if (notification == null) return;

    await _flutterLocalNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          importance: _androidChannel.importance,
          channelDescription: _androidChannel.description,
          icon: _defaultIcon,
          priority: Priority.max,
          category: AndroidNotificationCategory.status,
        ),
      ),
      payload: jsonEncode(message.toMap()),
    );
  }

  /// Displays a local notification with a given title and body.
  Future<void> showNotification({
    required int? id,
    required String title,
    required String body,
  }) async {
    return _flutterLocalNotificationsPlugin.show(
      id: id ?? 0,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          importance: _androidChannel.importance,
          channelDescription: _androidChannel.description,
          icon: _defaultIcon,
          priority: Priority.max,
          category: AndroidNotificationCategory.status,
        ),
      ),
    );
  }
}
