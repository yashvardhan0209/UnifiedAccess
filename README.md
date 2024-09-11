# UnifiedAuthNotify Package

**UnifiedAuthNotify** is a powerful Flutter package designed to simplify authentication and notification management. It integrates multiple authentication methods using Firebase (phone, email, Google, Apple, Facebook) and provides a unified notification service with local notifications and Firebase Cloud Messaging (FCM), all under one unified solution.

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

3. Import and initialize `UnifiedNotification` and `UnifiedAuthentication` in your app as required.

## Examples

### UnifiedAuthentication

### Phone & OTP Login
This example demonstrates how to use the UnifiedAuthentication class to perform Firebase phone number verification.
```
await auth.verifyPhoneNumber(
    phoneNumber: '1234567890',
    codeSent: (String verificationId, [int? forceResendingToken]) {
      // Handle code sent (e.g., show an OTP input field)
      final verificationId = verificationId;
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

final credentials  = await auth.authenticateWithOTP(
    otp: user input otp value,
    verificationId: verificationId,
)
```



