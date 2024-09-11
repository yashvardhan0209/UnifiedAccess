/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

export 'package:device_info_plus/device_info_plus.dart';
export 'package:firebase_app_check/firebase_app_check.dart';
export 'package:firebase_auth/firebase_auth.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_crashlytics/firebase_crashlytics.dart';
export 'package:firebase_messaging/firebase_messaging.dart'
    hide AuthorizationStatus;
export 'package:unified_access/src/unified_notification/model/fcm_device_info/fcm_device_info_model.dart';
export 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
export 'package:flutter_local_notifications/flutter_local_notifications.dart';
export 'package:google_sign_in/google_sign_in.dart';
export 'package:the_apple_sign_in/the_apple_sign_in.dart';

export 'src/unified_authentication/unified_authentication.dart';
export 'src/unified_notification/unified_notification.dart';
export 'src/firebase_exception.dart' show FirebaseAuthenticationException;

