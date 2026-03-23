import 'package:flutter/material.dart';
import 'package:unified_access/unified_access.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  final notificationService = UnifiedNotification();
  final settings = await notificationService.init(
    onOpenNotification: (message) {
      // Handle notification tap — use message?.data to navigate to a screen
      debugPrint('Notification tapped: ${message?.data}');
    },
    defaultIcon: 'app_icon',
    enableCloudMessaging: true,
  );
  debugPrint('Notification permission: ${settings?.authorizationStatus}');

  // Listen for FCM token refreshes
  notificationService.onTokenRefresh.listen((newToken) {
    debugPrint('FCM token refreshed: $newToken');
    // Send updated token to your backend
  });

  // Subscribe to a topic
  await notificationService.subscribeToTopic('general');

  // Initialize authentication
  final authService = UnifiedAuthentication();

  runApp(ExampleApp(authService: authService));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key, required this.authService});
  final UnifiedAuthentication authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          return Scaffold(
            appBar: AppBar(title: Text(user != null ? 'Logged In' : 'Login')),
            body: Center(
              child: user != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Welcome, ${user.email ?? user.phoneNumber}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => authService.firebaseSignOut(),
                          child: const Text('Sign Out'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await UnifiedNotification().showNotification(
                              id: 1,
                              title: 'Hello',
                              body: 'This is a test notification',
                            );
                          },
                          child: const Text('Send Test Notification'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await authService.emailLogin(
                                email: 'test@example.com',
                                password: 'password123',
                              );
                            } on FirebaseAuthenticationException catch (e) {
                              debugPrint(
                                'Login failed (${e.code}): ${e.message}',
                              );
                            }
                          },
                          child: const Text('Email Login'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await authService.signInWithGoogle();
                            } on FirebaseAuthenticationException catch (e) {
                              debugPrint(
                                'Google sign-in failed (${e.code}): ${e.message}',
                              );
                            }
                          },
                          child: const Text('Google Sign-In'),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
