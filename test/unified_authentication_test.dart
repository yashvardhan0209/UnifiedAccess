import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:unified_access/src/firebase_exception.dart';
import 'package:unified_access/src/unified_authentication/unified_authentication.dart';

// ---------- Fakes ----------

class FakeUserCredential extends Fake implements UserCredential {}

class FakeUser extends Fake implements User {
  bool deleted = false;
  String? deleteErrorCode;

  @override
  Future<void> delete() async {
    if (deleteErrorCode != null) {
      throw FirebaseAuthException(code: deleteErrorCode!);
    }
    deleted = true;
  }
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeUser? _currentUser;
  UserCredential? signInResult;
  String? signInErrorCode;
  UserCredential? createUserResult;
  String? createUserErrorCode;
  String? sendResetErrorCode;
  bool sendResetCalled = false;
  bool signOutCalled = false;
  String? signInWithCredentialErrorCode;
  UserCredential? signInWithCredentialResult;
  bool verifyPhoneNumberCalled = false;
  String? verifyPhoneNumberPhone;
  Duration? verifyPhoneNumberTimeout;
  int? verifyPhoneNumberResendToken;

  final _authStateController = StreamController<User?>.broadcast();
  final _userChangesController = StreamController<User?>.broadcast();

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user as FakeUser?;
  }

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  Stream<User?> userChanges() => _userChangesController.stream;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (signInErrorCode != null) {
      throw FirebaseAuthException(code: signInErrorCode!);
    }
    return signInResult!;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (createUserErrorCode != null) {
      throw FirebaseAuthException(code: createUserErrorCode!);
    }
    return createUserResult!;
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (sendResetErrorCode != null) {
      throw FirebaseAuthException(code: sendResetErrorCode!);
    }
    sendResetCalled = true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    if (signInWithCredentialErrorCode != null) {
      throw FirebaseAuthException(code: signInWithCredentialErrorCode!);
    }
    return signInWithCredentialResult!;
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    verifyPhoneNumberCalled = true;
    verifyPhoneNumberPhone = phoneNumber;
    verifyPhoneNumberTimeout = timeout;
    verifyPhoneNumberResendToken = forceResendingToken;
  }

  void dispose() {
    _authStateController.close();
    _userChangesController.close();
  }
}

class FakeGoogleSignInAuthentication extends Fake
    implements GoogleSignInAuthentication {
  @override
  String? get idToken => 'fake-google-id-token';
}

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  @override
  GoogleSignInAuthentication get authentication =>
      FakeGoogleSignInAuthentication();
}

class FakeAccessToken extends Fake implements AccessToken {
  @override
  String get tokenString => 'fake-fb-access-token';
}

void main() {
  late FakeFirebaseAuth fakeAuth;
  late UnifiedAuthentication authService;

  setUp(() {
    fakeAuth = FakeFirebaseAuth();
    UnifiedAuthentication.setAuthForTesting(fakeAuth);
    UnifiedAuthentication.resetGoogleSignInForTesting();
    authService = UnifiedAuthentication();
  });

  tearDown(() {
    fakeAuth.dispose();
  });

  group('UnifiedAuthentication singleton', () {
    test('factory returns same instance', () {
      final a = UnifiedAuthentication();
      final b = UnifiedAuthentication();
      expect(identical(a, b), isTrue);
    });
  });

  group('authStateChanges', () {
    test('delegates to FirebaseAuth.authStateChanges', () {
      final stream = authService.authStateChanges;
      expect(stream, isA<Stream<User?>>());
    });
  });

  group('userChanges', () {
    test('delegates to FirebaseAuth.userChanges', () {
      final stream = authService.userChanges;
      expect(stream, isA<Stream<User?>>());
    });
  });

  group('currentUser', () {
    test('returns null when no user signed in', () {
      expect(authService.currentUser, isNull);
    });

    test('returns user when signed in', () {
      fakeAuth.currentUser = FakeUser();
      expect(authService.currentUser, isNotNull);
    });
  });

  group('defaultVerificationFailed', () {
    test('throws FirebaseAuthenticationException', () async {
      expect(
        () => authService.defaultVerificationFailed(
          FirebaseAuthException(code: 'verification-failed'),
        ),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'verification-failed')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.verificationFailed,
              ),
        ),
      );
    });
  });

  group('defaultVerificationCompleted', () {
    test('does not throw', () {
      // PhoneAuthCredential can't be easily constructed, but we can use Fake
      authService.defaultVerificationCompleted(
        PhoneAuthProvider.credential(verificationId: 'vid', smsCode: '123456'),
      );
    });
  });

  group('defaultCodeAutoRetrievalTimeout', () {
    test('does not throw', () {
      authService.defaultCodeAutoRetrievalTimeout('verificationId123');
    });
  });

  group('verifyPhoneNumber', () {
    test('delegates to FirebaseAuth.verifyPhoneNumber with defaults', () async {
      await authService.verifyPhoneNumber(
        phoneNumber: '+1234567890',
        codeSent: (String verificationId, int? resendToken) {},
      );

      expect(fakeAuth.verifyPhoneNumberCalled, isTrue);
      expect(fakeAuth.verifyPhoneNumberPhone, '+1234567890');
      expect(fakeAuth.verifyPhoneNumberTimeout, const Duration(seconds: 60));
      expect(fakeAuth.verifyPhoneNumberResendToken, isNull);
    });

    test('uses custom timeout and forceResendingToken', () async {
      await authService.verifyPhoneNumber(
        phoneNumber: '+1234567890',
        codeSent: (String verificationId, int? resendToken) {},
        timeout: const Duration(seconds: 30),
        forceResendingToken: 42,
      );

      expect(fakeAuth.verifyPhoneNumberTimeout, const Duration(seconds: 30));
      expect(fakeAuth.verifyPhoneNumberResendToken, 42);
    });
  });

  group('authenticateWithOTP', () {
    test('throws when OTP is less than 6 digits', () {
      expect(
        () => authService.authenticateWithOTP(
          otp: '12345',
          verificationId: 'vid',
        ),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'invalid-otp')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.invalidOTP,
              ),
        ),
      );
    });

    test('throws when OTP is more than 6 digits', () {
      expect(
        () => authService.authenticateWithOTP(
          otp: '1234567',
          verificationId: 'vid',
        ),
        throwsA(
          isA<FirebaseAuthenticationException>().having(
            (e) => e.code,
            'code',
            'invalid-otp',
          ),
        ),
      );
    });

    test('throws when OTP is empty', () {
      expect(
        () => authService.authenticateWithOTP(otp: '', verificationId: 'vid'),
        throwsA(isA<FirebaseAuthenticationException>()),
      );
    });

    test('signs in with valid 6-digit OTP', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInWithCredentialResult = credential;

      final result = await authService.authenticateWithOTP(
        otp: '123456',
        verificationId: 'vid123',
      );

      expect(result, credential);
    });

    test('maps FirebaseAuthException from signInWithCredential', () {
      fakeAuth.signInWithCredentialErrorCode = 'invalid-credential';

      expect(
        () => authService.authenticateWithOTP(
          otp: '123456',
          verificationId: 'vid',
        ),
        throwsA(
          isA<FirebaseAuthenticationException>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          ),
        ),
      );
    });
  });

  group('emailLogin', () {
    test('returns UserCredential on success', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInResult = credential;

      final result = await authService.emailLogin(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, credential);
    });

    test('throws mapped exception on FirebaseAuthException', () {
      fakeAuth.signInErrorCode = 'wrong-password';

      expect(
        () => authService.emailLogin(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'wrong-password')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.wrongPassword,
              ),
        ),
      );
    });
  });

  group('emailSignUp', () {
    test('returns UserCredential on success', () async {
      final credential = FakeUserCredential();
      fakeAuth.createUserResult = credential;

      final result = await authService.emailSignUp(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, credential);
    });

    test('throws on email-already-in-use', () {
      fakeAuth.createUserErrorCode = 'email-already-in-use';

      expect(
        () => authService.emailSignUp(
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'email-already-in-use')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.emailAlreadyInUse,
              ),
        ),
      );
    });

    test('throws on weak-password', () {
      fakeAuth.createUserErrorCode = 'weak-password';

      expect(
        () => authService.emailSignUp(email: 'test@example.com', password: '1'),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'weak-password')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.weakPassword,
              ),
        ),
      );
    });
  });

  group('sendPasswordResetEmail', () {
    test('completes on success', () async {
      await authService.sendPasswordResetEmail(email: 'test@example.com');
      expect(fakeAuth.sendResetCalled, isTrue);
    });

    test('throws on user-not-found', () {
      fakeAuth.sendResetErrorCode = 'user-not-found';

      expect(
        () => authService.sendPasswordResetEmail(email: 'missing@example.com'),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'user-not-found')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.userNotFound,
              ),
        ),
      );
    });
  });

  group('deleteAccount', () {
    test('throws when no user is signed in', () {
      expect(
        () => authService.deleteAccount(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'user-not-found')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.userNotFound,
              ),
        ),
      );
    });

    test('deletes user account successfully', () async {
      final fakeUser = FakeUser();
      fakeAuth.currentUser = fakeUser;

      await authService.deleteAccount();

      expect(fakeUser.deleted, isTrue);
    });

    test('throws on requires-recent-login', () {
      final fakeUser = FakeUser()..deleteErrorCode = 'requires-recent-login';
      fakeAuth.currentUser = fakeUser;

      expect(
        () => authService.deleteAccount(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'requires-recent-login')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.requiresRecentLogin,
              ),
        ),
      );
    });
  });

  group('signInWithGoogle', () {
    setUp(() {
      UnifiedAuthentication.resetGoogleSignInForTesting();
    });

    test('initializes and signs in successfully', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInWithCredentialResult = credential;
      bool initCalled = false;

      UnifiedAuthentication.setSocialProvidersForTesting(
        googleInitialize: () async {
          initCalled = true;
        },
        googleAuthenticate: () async => FakeGoogleSignInAccount(),
      );

      final result = await authService.signInWithGoogle();

      expect(result, credential);
      expect(initCalled, isTrue);
    });

    test('skips initialization on second call', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInWithCredentialResult = credential;
      int initCount = 0;

      UnifiedAuthentication.setSocialProvidersForTesting(
        googleInitialize: () async {
          initCount++;
        },
        googleAuthenticate: () async => FakeGoogleSignInAccount(),
      );

      await authService.signInWithGoogle();
      await authService.signInWithGoogle();

      expect(initCount, 1);
    });

    test('maps FirebaseAuthException from signInWithCredential', () {
      fakeAuth.signInWithCredentialErrorCode = 'invalid-credential';

      UnifiedAuthentication.setSocialProvidersForTesting(
        googleInitialize: () async {},
        googleAuthenticate: () async => FakeGoogleSignInAccount(),
      );

      expect(
        () => authService.signInWithGoogle(),
        throwsA(
          isA<FirebaseAuthenticationException>().having(
            (e) => e.code,
            'code',
            'invalid-credential',
          ),
        ),
      );
    });
  });

  group('signInWithApple', () {
    test('signs in successfully when authorized', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInWithCredentialResult = credential;

      UnifiedAuthentication.setSocialProvidersForTesting(
        applePerformRequests: (requests) async => AuthorizationResult(
          status: AuthorizationStatus.authorized,
          credential: AppleIdCredential(
            identityToken: Uint8List.fromList('fake-id-token'.codeUnits),
            authorizationCode: Uint8List.fromList('fake-auth-code'.codeUnits),
          ),
        ),
      );

      final result = await authService.signInWithApple();
      expect(result, credential);
    });

    test('throws on error status', () {
      UnifiedAuthentication.setSocialProvidersForTesting(
        applePerformRequests: (requests) async =>
            const AuthorizationResult(status: AuthorizationStatus.error),
      );

      expect(
        () => authService.signInWithApple(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'apple-sign-in-error')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.invalidVerificationCode,
              ),
        ),
      );
    });

    test('throws on cancelled status', () {
      UnifiedAuthentication.setSocialProvidersForTesting(
        applePerformRequests: (requests) async =>
            const AuthorizationResult(status: AuthorizationStatus.cancelled),
      );

      expect(
        () => authService.signInWithApple(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'aborted-by-user')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.abortedByUser,
              ),
        ),
      );
    });
  });

  group('signInWithFacebook', () {
    test('signs in successfully', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInWithCredentialResult = credential;

      UnifiedAuthentication.setSocialProvidersForTesting(
        facebookLogin: ({required List<String> permissions}) async =>
            LoginResult(
              status: LoginStatus.success,
              accessToken: FakeAccessToken(),
            ),
      );

      final result = await authService.signInWithFacebook();
      expect(result, credential);
    });

    test('uses custom permissions', () async {
      final credential = FakeUserCredential();
      fakeAuth.signInWithCredentialResult = credential;
      List<String>? receivedPermissions;

      UnifiedAuthentication.setSocialProvidersForTesting(
        facebookLogin: ({required List<String> permissions}) async {
          receivedPermissions = permissions;
          return LoginResult(
            status: LoginStatus.success,
            accessToken: FakeAccessToken(),
          );
        },
      );

      await authService.signInWithFacebook(
        permissions: ['email', 'user_friends'],
      );
      expect(receivedPermissions, ['email', 'user_friends']);
    });

    test('throws on failed status', () {
      UnifiedAuthentication.setSocialProvidersForTesting(
        facebookLogin: ({required List<String> permissions}) async =>
            LoginResult(status: LoginStatus.failed),
      );

      expect(
        () => authService.signInWithFacebook(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'facebook-login-failed')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.invalidVerificationCode,
              ),
        ),
      );
    });

    test('throws on cancelled status', () {
      UnifiedAuthentication.setSocialProvidersForTesting(
        facebookLogin: ({required List<String> permissions}) async =>
            LoginResult(status: LoginStatus.cancelled),
      );

      expect(
        () => authService.signInWithFacebook(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'aborted-by-user')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.abortedByUser,
              ),
        ),
      );
    });

    test('throws on operationInProgress status', () {
      UnifiedAuthentication.setSocialProvidersForTesting(
        facebookLogin: ({required List<String> permissions}) async =>
            LoginResult(status: LoginStatus.operationInProgress),
      );

      expect(
        () => authService.signInWithFacebook(),
        throwsA(
          isA<FirebaseAuthenticationException>()
              .having((e) => e.code, 'code', 'unknown')
              .having(
                (e) => e.message,
                'message',
                FirebaseExceptionMessage.unknownError,
              ),
        ),
      );
    });

    test('throws when accessToken is null on success status', () {
      UnifiedAuthentication.setSocialProvidersForTesting(
        facebookLogin: ({required List<String> permissions}) async =>
            LoginResult(status: LoginStatus.success, accessToken: null),
      );

      expect(
        () => authService.signInWithFacebook(),
        throwsA(isA<FirebaseAuthenticationException>()),
      );
    });
  });

  group('firebaseSignOut', () {
    test('calls signOut on auth and social providers', () async {
      bool googleSignOutCalled = false;
      bool facebookLogOutCalled = false;

      UnifiedAuthentication.setSocialProvidersForTesting(
        googleSignOut: () async {
          googleSignOutCalled = true;
        },
        facebookLogOut: () async {
          facebookLogOutCalled = true;
        },
      );

      await authService.firebaseSignOut();

      expect(fakeAuth.signOutCalled, isTrue);
      expect(googleSignOutCalled, isTrue);
      expect(facebookLogOutCalled, isTrue);
    });
  });

  group('_mapFirebaseErrorMessage coverage', () {
    // Test all error code mappings through emailLogin
    final errorMappings = <String, String>{
      'invalid-email': FirebaseExceptionMessage.invalidEmailId,
      'user-disabled': FirebaseExceptionMessage.userDisabled,
      'user-not-found': FirebaseExceptionMessage.userNotFound,
      'wrong-password': FirebaseExceptionMessage.wrongPassword,
      'invalid-credential': FirebaseExceptionMessage.invalidCredential,
      'email-already-in-use': FirebaseExceptionMessage.emailAlreadyInUse,
      'weak-password': FirebaseExceptionMessage.weakPassword,
      'too-many-requests': FirebaseExceptionMessage.tooManyRequests,
      'network-request-failed': FirebaseExceptionMessage.networkRequestFailed,
      'requires-recent-login': FirebaseExceptionMessage.requiresRecentLogin,
      'account-exists-with-different-credential':
          FirebaseExceptionMessage.accountExistsWithDifferentCredential,
      'operation-not-allowed': FirebaseExceptionMessage.operationNotAllowed,
      'some-unknown-code': FirebaseExceptionMessage.unknownError,
    };

    for (final entry in errorMappings.entries) {
      test('maps "${entry.key}" to correct message', () {
        // Reset for each test
        fakeAuth.signInErrorCode = entry.key;

        expect(
          () => authService.emailLogin(
            email: 'test@example.com',
            password: 'pass',
          ),
          throwsA(
            isA<FirebaseAuthenticationException>()
                .having((e) => e.code, 'code', entry.key)
                .having((e) => e.message, 'message', entry.value),
          ),
        );
      });
    }
  });
}
