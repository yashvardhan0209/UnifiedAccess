# UnifiedAccess Package

**UnifiedAccess** is a powerful Flutter package designed to simplify authentication and notification management. It integrates multiple authentication methods using Firebase (phone, email, Google, Apple, Facebook) and provides a unified notification service with local notifications and Firebase Cloud Messaging (FCM), all under one unified solution.

## Features

This package provides the following functionalities:

- **Unified Authentication**: Supports multiple authentication methods, including phone verification, email login, Google, Apple, and Facebook sign-in, with custom exception handling.
- **Unified Notifications**: Manage both local notifications and Firebase Cloud Messaging (FCM) with seamless integration and custom notification channels.
- Handle background and foreground notifications.
- Retrieve device information and FCM tokens.
- Customizable notification click callbacks for user interactions.

## Prerequisites

Before using this package, ensure you have:

1. **Firebase setup**: Add Firebase to your Flutter project. For more details, follow the official Firebase setup guide for [Flutter](https://firebase.flutter.dev/docs/overview).
2. **Google, Facebook, and Apple Sign-In Configuration**: Set up Google, Facebook, and Apple sign-in services in your Firebase console.
3. **Permissions**: Ensure your Android and iOS apps request the necessary permissions for notifications and authentication.

## How to Use

1. Add the package to your `pubspec.yaml`:

```
   dependencies:
     unified_auth_notify: ^1.0.0
```

2. Initialize Firebase in your `main.dart`:

```
void main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await Firebase.initializeApp();
        runApp(MyApp());
}
```

3. Import and initialize `UnifiedNotification` and `UnifiedAuthentication` in your app.

```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize authentication
  UnifiedAuthentication authenticationService = UnifiedAuthentication();

  // Initialize notifications
  UnifiedNotification notificationService = UnifiedNotification();

  await notificationService.init(
    onOpenNotification: () {
      // Custom logic when a notification is clicked
      print('Notification clicked');
    },
    defaultIcon: 'app_icon', // Provide your app icon
    enableCloudMessaging: true, // Enable Firebase Cloud Messaging
  );

  runApp(MyApp());
}
```

## Authentication Examples

### Phone & OTP Login

This example demonstrates how to use the UnifiedAuthentication class to perform Firebase Phone Number & OTP Login.

```
await auth.verifyPhoneNumber(
    phoneNumber: '1234567890',
    codeSent: (String verificationId, [int? forceResendingToken]) {
      final verificationId = verificationId;
      // Handle code sent (e.g., show an OTP input field)
    },
    verificationFailed: (FirebaseAuthException e) {
      // Handle verification failure
      print('Verification failed: ${e.message}');
    },
    verificationCompleted: (PhoneAuthCredential credential) {
      // Handle automatic verification
      print('Phone verified: ${credential}');
    },
    codeAutoRetrievalTimeout: (String verificationId) {
      // Handle timeout
      print('Auto retrieval timeout');
    },
);

/// verify otp
final credentials  = await auth.authenticateWithOTP(
    otp: user input otp value,
    verificationId: verificationId,
)
```

### Email Login

This example demonstrates how to use the UnifiedAuthentication class to perform Firebase Email Login.

```
try {
    UserCredential userCredential = await auth.emailLogin(
      email: 'test@example.com',
      password: 'password123',
    );
    print('Logged in as: ${userCredential.user?.email}');
  } catch (e) {
    // Handle any errors that occur during the sign-in process
    print('Login failed: ${e}');
  }
```

### Google Login

This example demonstrates how to use the UnifiedAuthentication class to perform Firebase Google Login.

```
try {
    UserCredential googleUser = await auth.signInWithGoogle();
    print('Google user: ${googleUser.user?.email}');
  } catch (e) {
    // Handle any errors that occur during the sign-in process
    print('Google sign-in failed: ${e}');
  }
```

### Apple Login

This example demonstrates how to use the UnifiedAuthentication class to perform Firebase Apple Login.

```
try {
    UserCredential userCredential = await auth.signInWithApple(
      scopes: [Scope.email, Scope.fullName],
    );
    print('Signed in with Apple as: ${userCredential.user?.email}');
  } catch (e) {
    // Handle any errors that occur during the sign-in process
    print('Apple sign-in failed: $e');
  }
```

### Facebook Login

This example demonstrates how to use the UnifiedAuthentication class to perform Firebase Facebook Login.

```
try {
    UserCredential userCredential = await auth.signInWithFacebook(
      permissions: ['email', 'public_profile'],
    );
    print('Signed in with Facebook as: ${userCredential.user?.email}');
  } catch (e) {
    // Handle any errors that occur during the sign-in process
    print('Facebook sign-in failed: $e');
  }
```

### Sign Out

This example demonstrates how to use the UnifiedAuthentication class to perform Firebase Sing Out.

```
try {
    await auth.firebaseSignOut();
    print('User successfully signed out.');
  } catch (e) {
    // Handle any errors that occur during the sign-out process
    print('Sign-out failed: $e');
  }
```

## Notification Examples

### Get FCM Token

The `getFcmToken` method retrieves the `Firebase Cloud Messaging (FCM) token` and device information.

```
  FcmDeviceInfoModel? deviceInfo = await notificationService.getFcmToken();

  // Print FCM token and device details
  if (deviceInfo != null) {
    print('FCM Token: ${deviceInfo.fcmToken}');
    if (deviceInfo.androidDeviceInfo != null) {
      print('Android Device Info: ${deviceInfo.androidDeviceInfo!.model}');
    } else if (deviceInfo.iosDeviceInfo != null) {
      print('iOS Device Info: ${deviceInfo.iosDeviceInfo!.name}');
    }
  }
```

### Show/Trigger Notification

The `showNotification` method is used to display a local notification.

```
  await notificationService.showNotification(
    id: 1, // Unique notification ID
    title: 'Test Notification', // Notification title
    body: 'This is a test notification body', // Notification body
  );
```

## More About the Package

UnifiedAccess simplifies the integration of Firebase Authentication and Notification services, ensuring you only need to set up once, reducing the need for multiple dependencies. It’s designed for developers who want to streamline user authentication and push notifications, especially for apps that require multiple sign-in options and local/FCM notifications.

By using UnifiedAccess, you eliminate the complexity of handling various authentication and notification services individually, allowing you to focus on building amazing features in your app.

You are more than welcome to contribute to this package.

## Developed by:

![Mask type](https://wsrv.nl/?url=https://github.com/dewbambs/flutter_pinelab_peripheralappservice/assets/97099753/63b172ce-8bec-44c2-981c-55dab7389ecb&w=80&h=80&fit=cover&mask=circle)

Yash Vardhan
