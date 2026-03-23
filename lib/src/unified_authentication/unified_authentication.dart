// ignore_for_file: no_default_cases, unreachable_switch_default

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:unified_access/src/firebase_exception.dart';

class UnifiedAuthentication {
  /// Singleton instance of UnifiedAuthentication
  factory UnifiedAuthentication() {
    return _singleton;
  }

  UnifiedAuthentication._internal();

  static final UnifiedAuthentication _singleton =
      UnifiedAuthentication._internal();

  /// Firebase Auth Instance
  late FirebaseAuth _auth = FirebaseAuth.instance; // coverage:ignore-line

  // Injectable function wrappers for social sign-in providers.
  // These allow unit tests to replace static SDK calls with fakes.
  // coverage:ignore-start
  Future<void> Function() _googleInitialize = () =>
      GoogleSignIn.instance.initialize();
  Future<GoogleSignInAccount> Function() _googleAuthenticate = () =>
      GoogleSignIn.instance.authenticate();
  Future<void> Function() _googleSignOut = () =>
      GoogleSignIn.instance.signOut();

  Future<AuthorizationResult> Function(List<AuthorizationRequest>)
  _applePerformRequests = TheAppleSignIn.performRequests;

  Future<LoginResult> Function({required List<String> permissions})
  _facebookLogin = ({required List<String> permissions}) =>
      FacebookAuth.instance.login(permissions: permissions);
  Future<void> Function() _facebookLogOut = () =>
      FacebookAuth.instance.logOut();
  // coverage:ignore-end

  /// Overrides the [FirebaseAuth] instance used by this service.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  static void setAuthForTesting(FirebaseAuth auth) {
    _singleton._auth = auth;
  }

  /// Overrides social sign-in providers for testing.
  @visibleForTesting
  static void setSocialProvidersForTesting({
    Future<void> Function()? googleInitialize,
    Future<GoogleSignInAccount> Function()? googleAuthenticate,
    Future<void> Function()? googleSignOut,
    Future<AuthorizationResult> Function(List<AuthorizationRequest>)?
    applePerformRequests,
    Future<LoginResult> Function({required List<String> permissions})?
    facebookLogin,
    Future<void> Function()? facebookLogOut,
  }) {
    if (googleInitialize != null) {
      _singleton._googleInitialize = googleInitialize;
    }
    if (googleAuthenticate != null) {
      _singleton._googleAuthenticate = googleAuthenticate;
    }
    if (googleSignOut != null) _singleton._googleSignOut = googleSignOut;
    if (applePerformRequests != null) {
      _singleton._applePerformRequests = applePerformRequests;
    }
    if (facebookLogin != null) _singleton._facebookLogin = facebookLogin;
    if (facebookLogOut != null) _singleton._facebookLogOut = facebookLogOut;
  }

  /// Resets the Google Sign-In initialized flag for testing.
  @visibleForTesting
  static void resetGoogleSignInForTesting() {
    _googleSignInInitialized = false;
  }

  /// Stream of authentication state changes. Use this with [StreamBuilder]
  /// to reactively rebuild UI on login/logout.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of user changes including profile updates and token refreshes.
  Stream<User?> get userChanges => _auth.userChanges();

  /// The currently signed-in user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Default method for handling verification failures if [verificationFailed] is not provided.
  @visibleForTesting
  Future<void> defaultVerificationFailed(
    FirebaseAuthException verificationFailed,
  ) async {
    throw FirebaseAuthenticationException(
      message: FirebaseExceptionMessage.verificationFailed,
      code: 'verification-failed',
    );
  }

  /// Default method for handling verification completion if [verificationCompleted] is not provided.
  @visibleForTesting
  void defaultVerificationCompleted(PhoneAuthCredential credential) {}

  /// Default method for handling auto-retrieval timeout if [codeAutoRetrievalTimeout] is not provided.
  @visibleForTesting
  void defaultCodeAutoRetrievalTimeout(String verificationId) {}

  /// Firebase phone number verification method.
  ///
  /// Verifies the provided [phoneNumber] and triggers [codeSent] when a code is sent.
  /// Make sure to provided [phoneNumber] along with country code.
  /// It also handles optional callbacks for [verificationCompleted], [verificationFailed], and [codeAutoRetrievalTimeout].
  /// Throws [FirebaseAuthenticationException] for invalid phone numbers or authentication failures.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneCodeSent codeSent,
    Duration? timeout,
    PhoneVerificationCompleted? verificationCompleted,
    PhoneVerificationFailed? verificationFailed,
    PhoneCodeAutoRetrievalTimeout? codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout ?? const Duration(seconds: 60),
      verificationCompleted:
          verificationCompleted ?? defaultVerificationCompleted,
      verificationFailed: verificationFailed ?? defaultVerificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout:
          codeAutoRetrievalTimeout ?? defaultCodeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  /// Authenticates the user using the provided [otp] and [verificationId].
  /// Throws [FirebaseAuthenticationException] for invalid OTPs or authentication failures.
  Future<UserCredential> authenticateWithOTP({
    required String otp,
    required String verificationId,
  }) async {
    if (otp.length != 6) {
      throw FirebaseAuthenticationException(
        message: FirebaseExceptionMessage.invalidOTP,
        code: 'invalid-otp',
      );
    }

    final phoneAuthCredential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    return _signInWithCredential(phoneAuthCredential);
  }

  /// Authenticates the user using Firebase email and password.
  Future<UserCredential> emailLogin({
    required String email,
    required String password,
  }) async {
    return _handleFirebaseAuthExceptions(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  /// Creates a new user account with email and password.
  /// Throws [FirebaseAuthenticationException] for duplicate emails or weak passwords.
  Future<UserCredential> emailSignUp({
    required String email,
    required String password,
  }) async {
    return _handleFirebaseAuthExceptions(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  /// Sends a password reset email using Firebase.
  Future<void> sendPasswordResetEmail({required String email}) async {
    return _handleFirebaseAuthExceptions(
      () => _auth.sendPasswordResetEmail(email: email),
    );
  }

  /// Deletes the currently signed-in user account.
  /// Required by Apple App Store guidelines.
  /// May throw [FirebaseAuthenticationException] with code 'requires-recent-login'
  /// if the user hasn't signed in recently.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthenticationException(
        message: FirebaseExceptionMessage.userNotFound,
        code: 'user-not-found',
      );
    }
    return _handleFirebaseAuthExceptions(() => user.delete());
  }

  static bool _googleSignInInitialized = false;

  /// Google login using Firebase Authentication.
  ///
  /// Callers who need custom Google Sign-In configuration (e.g. clientId,
  /// serverClientId) should call [GoogleSignIn.instance.initialize] themselves
  /// before invoking this method.
  Future<UserCredential> signInWithGoogle() async {
    if (!_googleSignInInitialized) {
      await _googleInitialize();
      _googleSignInInitialized = true;
    }

    final googleAccount = await _googleAuthenticate();
    final googleAuth = googleAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _signInWithCredential(credential);
  }

  /// Apple login using Firebase Authentication.
  Future<UserCredential> signInWithApple({
    List<Scope> scopes = const [],
  }) async {
    final result = await _applePerformRequests([
      AppleIdRequest(requestedScopes: scopes),
    ]);
    return _handleAppleSignIn(result, scopes);
  }

  /// Facebook login using Firebase Authentication.
  Future<UserCredential> signInWithFacebook({List<String>? permissions}) async {
    final loginResult = await _facebookLogin(
      permissions: permissions ?? ['email', 'public_profile'],
    );

    if (loginResult.status == LoginStatus.success &&
        loginResult.accessToken?.tokenString != null) {
      final credential = FacebookAuthProvider.credential(
        loginResult.accessToken!.tokenString,
      );
      return _signInWithCredential(credential);
    }

    throw _mapFacebookLoginError(loginResult);
  }

  /// Signs out from Firebase and all social providers (Google, Facebook).
  Future<void> firebaseSignOut() async {
    await Future.wait([_auth.signOut(), _googleSignOut(), _facebookLogOut()]);
  }

  // --------------------- Private Helper Methods -------------------------

  /// Signs in using the provided [AuthCredential].
  Future<UserCredential> _signInWithCredential(
    AuthCredential credential,
  ) async {
    return _handleFirebaseAuthExceptions(
      () => _auth.signInWithCredential(credential),
    );
  }

  /// Handles FirebaseAuthException and throws appropriate custom exceptions.
  Future<T> _handleFirebaseAuthExceptions<T>(
    Future<T> Function() authFunction,
  ) async {
    try {
      return await authFunction();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthenticationException(
        message: _mapFirebaseErrorMessage(error.code),
        code: error.code,
      );
    }
  }

  /// Maps FirebaseAuth error codes to custom error messages.
  String _mapFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return FirebaseExceptionMessage.invalidEmailId;
      case 'user-disabled':
        return FirebaseExceptionMessage.userDisabled;
      case 'user-not-found':
        return FirebaseExceptionMessage.userNotFound;
      case 'wrong-password':
        return FirebaseExceptionMessage.wrongPassword;
      case 'invalid-credential':
        return FirebaseExceptionMessage.invalidCredential;
      case 'email-already-in-use':
        return FirebaseExceptionMessage.emailAlreadyInUse;
      case 'weak-password':
        return FirebaseExceptionMessage.weakPassword;
      case 'too-many-requests':
        return FirebaseExceptionMessage.tooManyRequests;
      case 'network-request-failed':
        return FirebaseExceptionMessage.networkRequestFailed;
      case 'requires-recent-login':
        return FirebaseExceptionMessage.requiresRecentLogin;
      case 'account-exists-with-different-credential':
        return FirebaseExceptionMessage.accountExistsWithDifferentCredential;
      case 'operation-not-allowed':
        return FirebaseExceptionMessage.operationNotAllowed;
      default:
        return FirebaseExceptionMessage.unknownError;
    }
  }

  /// Handles Apple Sign-In result and returns the authenticated UserCredential.
  Future<UserCredential> _handleAppleSignIn(
    AuthorizationResult result,
    List<Scope> scopes,
  ) async {
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final credential = OAuthProvider('apple.com').credential(
          idToken: String.fromCharCodes(result.credential!.identityToken!),
          accessToken: String.fromCharCodes(
            result.credential!.authorizationCode!,
          ),
        );
        final userCredential = await _signInWithCredential(credential);
        return userCredential;
      case AuthorizationStatus.error:
        throw FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.invalidVerificationCode,
          code: 'apple-sign-in-error',
        );
      case AuthorizationStatus.cancelled:
        throw FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.abortedByUser,
          code: 'aborted-by-user',
        );
      // coverage:ignore-start
      default:
        throw FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.unknownError,
          code: 'unknown',
        );
      // coverage:ignore-end
    }
  }

  /// Maps Facebook login result errors to FirebaseAuthenticationException.
  FirebaseAuthenticationException _mapFacebookLoginError(
    LoginResult loginResult,
  ) {
    switch (loginResult.status) {
      case LoginStatus.failed:
        return FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.invalidVerificationCode,
          code: 'facebook-login-failed',
        );
      case LoginStatus.cancelled:
        return FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.abortedByUser,
          code: 'aborted-by-user',
        );
      default:
        return FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.unknownError,
          code: 'unknown',
        );
    }
  }
}
