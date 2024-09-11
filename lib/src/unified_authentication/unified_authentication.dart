// ignore_for_file: no_default_cases

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:unified_access/src/firebase_exception.dart';

class UnifiedAuthentication {
  /// Singleton instance of UnifiedAuthentication
  factory UnifiedAuthentication() {
    _singleton.auth = FirebaseAuth.instance;
    return _singleton;
  }

  UnifiedAuthentication._internal();

  static final UnifiedAuthentication _singleton =
      UnifiedAuthentication._internal();

  /// Firebase Auth Instance
  late FirebaseAuth auth;

  /// Default method for handling verification failures if [verificationFailed] is not provided.
  @visibleForTesting
  Future<void> defaultVerificationFailed(
    FirebaseAuthException verificationFailed,
  ) async {
    throw FirebaseAuthenticationException(
      message: FirebaseExceptionMessage.verificationFailed,
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
    if (phoneNumber.length != 10) {
      throw FirebaseAuthenticationException(
        message: FirebaseExceptionMessage.invalidPhoneNumber,
      );
    }

    await auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
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
      () => auth.signInWithEmailAndPassword(email: email, password: password),
    );
  }

  /// Sends a password reset email using Firebase.
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    return _handleFirebaseAuthExceptions(
      () => auth.sendPasswordResetEmail(email: email),
    );
  }

  /// Google login using Firebase Authentication.
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleAccount = await googleSignIn.signIn();

    if (googleAccount == null) {
      throw FirebaseAuthenticationException(
        message: FirebaseExceptionMessage.invalidVerificationId,
      );
    }

    final googleAuth = await googleAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _signInWithCredential(credential);
  }

  /// Apple login using Firebase Authentication.
  Future<UserCredential> signInWithApple(
      {List<Scope> scopes = const []}) async {
    final result = await TheAppleSignIn.performRequests(
      [AppleIdRequest(requestedScopes: scopes)],
    );
    return _handleAppleSignIn(result, scopes);
  }

  /// Facebook login using Firebase Authentication.
  Future<UserCredential> signInWithFacebook({
    List<String>? permissions,
  }) async {
    final loginResult = await FacebookAuth.instance.login(
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

  /// Firebase sign-out method.
  Future<void> firebaseSignOut() async {
    await auth.signOut();
  }

  // --------------------- Private Helper Methods -------------------------

  /// Signs in using the provided [AuthCredential].
  Future<UserCredential> _signInWithCredential(
      AuthCredential credential) async {
    return _handleFirebaseAuthExceptions(
      () => auth.signInWithCredential(credential),
    );
  }

  /// Handles FirebaseAuthException and throws appropriate custom exceptions.
  Future<T> _handleFirebaseAuthExceptions<T>(
      Future<T> Function() authFunction) async {
    try {
      return await authFunction();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthenticationException(
        message: _mapFirebaseErrorMessage(error.code),
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
          accessToken:
              String.fromCharCodes(result.credential!.authorizationCode!),
        );
        final userCredential = await _signInWithCredential(credential);
        return userCredential;
      case AuthorizationStatus.error:
        throw FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.invalidVerificationCode,
        );
      case AuthorizationStatus.cancelled:
        throw FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.abortedByUser,
        );
      default:
        throw FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.unknownError,
        );
    }
  }

  /// Maps Facebook login result errors to FirebaseAuthenticationException.
  FirebaseAuthenticationException _mapFacebookLoginError(
      LoginResult loginResult) {
    switch (loginResult.status) {
      case LoginStatus.failed:
        return FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.invalidVerificationCode,
        );
      case LoginStatus.cancelled:
        return FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.abortedByUser,
        );
      default:
        return FirebaseAuthenticationException(
          message: FirebaseExceptionMessage.unknownError,
        );
    }
  }
}
