// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:unified_access/src/unified_notification/model/fcm_device_info/fcm_device_info_model.dart';

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

  /// Callback when a notification is clicked.
  late VoidCallback onOpenNotification;

  /// Default icon for Android notifications.
  late String _defaultIcon;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel for important notifications.
  final _androidChannel = const AndroidNotificationChannel(
    'com.google.firebase.messaging.default_notification_channel_id',
    'high_importance_channel',
    description: 'This Channel is used for important notifications.',
    importance: Importance.max,
  );

  /// Retrieves FCM token and device information.
  Future<FcmDeviceInfoModel?> getFcmToken() async {
    final fcmToken = await _firebaseMessaging.getToken() ?? '';

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      return FcmDeviceInfoModel(
          fcmToken: fcmToken, androidDeviceInfo: deviceInfo);
    } else if (Platform.isIOS) {
      final deviceInfo = await DeviceInfoPlugin().iosInfo;
      return FcmDeviceInfoModel(fcmToken: fcmToken, iosDeviceInfo: deviceInfo);
    } else {
      return FcmDeviceInfoModel(fcmToken: fcmToken);
    }
  }

  /// Initializes notification services, setting up local notifications and optionally enabling Firebase Cloud Messaging (FCM).
  /// @param [onOpenNotification] Callback triggered when a notification is clicked
  /// @param [defaultIcon] Default icon for Android notifications
  /// @param [enableCloudMessaging] Enables Firebase Cloud Messaging if true
  Future<void> init({
    required VoidCallback onOpenNotification,
    required String defaultIcon,
    bool enableCloudMessaging = false,
  }) async {
    _defaultIcon = defaultIcon;
    _firebaseNotificationService.onOpenNotification = onOpenNotification;

    await _initLocalNotification();

    if (enableCloudMessaging) {
      await _firebaseMessaging.requestPermission();
      await _initFirebaseCloudMessaging();
    }
  }

  /// Initializes Firebase Cloud Messaging (FCM) to handle notifications in various states.
  Future<void> _initFirebaseCloudMessaging() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _firebaseMessaging.getInitialMessage().then(_handleMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  /// Initializes local notification settings for both Android and iOS.
  Future<void> _initLocalNotification() async {
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings(_defaultIcon),
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
        _handleMessage(message);
      },
    );

    final platform =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await platform?.createNotificationChannel(_androidChannel);
  }

  /// Handles background notification clicks.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    _firebaseNotificationService.onOpenNotification.call();
  }

  /// Handles incoming Firebase messages and displays them as local notifications.
  Future<void> _handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    final notification = message.notification;
    if (notification == null) return;

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
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
      id ?? 0,
      title,
      body,
      NotificationDetails(
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
