import 'package:flutter_test/flutter_test.dart';
import 'package:unified_access/src/firebase_exception.dart';

void main() {
  group('FirebaseExceptionMessage', () {
    test('abortedByUser has correct value', () {
      expect(FirebaseExceptionMessage.abortedByUser, 'Sign in aborted by user');
    });

    test('invalidEmailId has correct value', () {
      expect(
        FirebaseExceptionMessage.invalidEmailId,
        'Invalid email id. Please enter a valid email Id.',
      );
    });

    test('wrongPassword has correct value', () {
      expect(
        FirebaseExceptionMessage.wrongPassword,
        'Wrong password. Please enter the correct password.',
      );
    });

    test('invalidPhoneNumber has correct value', () {
      expect(
        FirebaseExceptionMessage.invalidPhoneNumber,
        'Invalid phone number. Please input a valid phone number.',
      );
    });

    test('userNotFound has correct value', () {
      expect(
        FirebaseExceptionMessage.userNotFound,
        'This user does not exist. Contact admin for registration.',
      );
    });

    test('verificationFailed has correct value', () {
      expect(
        FirebaseExceptionMessage.verificationFailed,
        'Phone number verification failed. Please try again.',
      );
    });

    test('invalidOTP has correct value', () {
      expect(
        FirebaseExceptionMessage.invalidOTP,
        'Invalid OTP entered. Please enter a 6 digit OTP.',
      );
    });

    test('invalidCredential has correct value', () {
      expect(
        FirebaseExceptionMessage.invalidCredential,
        'The given credential is malformed. Please try again.',
      );
    });

    test('operationNotAllowed has correct value', () {
      expect(
        FirebaseExceptionMessage.operationNotAllowed,
        'This operation is not allowed. Please contact admin for details.',
      );
    });

    test('userDisabled has correct value', () {
      expect(
        FirebaseExceptionMessage.userDisabled,
        'This user has been disabled. Please contact admin for details.',
      );
    });

    test('invalidVerificationCode has correct value', () {
      expect(
        FirebaseExceptionMessage.invalidVerificationCode,
        'Unable to verify user. Please login again.',
      );
    });

    test('invalidVerificationId has correct value', () {
      expect(
        FirebaseExceptionMessage.invalidVerificationId,
        'Unable to verify user. Please login again.',
      );
    });

    test('emailAlreadyInUse has correct value', () {
      expect(
        FirebaseExceptionMessage.emailAlreadyInUse,
        'This email is already registered. Please sign in or use a different email.',
      );
    });

    test('weakPassword has correct value', () {
      expect(
        FirebaseExceptionMessage.weakPassword,
        'Password is too weak. Please use a stronger password.',
      );
    });

    test('tooManyRequests has correct value', () {
      expect(
        FirebaseExceptionMessage.tooManyRequests,
        'Too many requests. Please try again later.',
      );
    });

    test('networkRequestFailed has correct value', () {
      expect(
        FirebaseExceptionMessage.networkRequestFailed,
        'Network error. Please check your internet connection and try again.',
      );
    });

    test('requiresRecentLogin has correct value', () {
      expect(
        FirebaseExceptionMessage.requiresRecentLogin,
        'This operation requires recent login. Please sign in again and retry.',
      );
    });

    test('accountExistsWithDifferentCredential has correct value', () {
      expect(
        FirebaseExceptionMessage.accountExistsWithDifferentCredential,
        'An account already exists with the same email but a different sign-in method.',
      );
    });

    test('unknownError has correct value', () {
      expect(
        FirebaseExceptionMessage.unknownError,
        'Unknown Error! Please contact admin for details.',
      );
    });
  });

  group('FirebaseAuthenticationException', () {
    test('creates with required message', () {
      final exception = FirebaseAuthenticationException(message: 'Test error');
      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates with all parameters', () {
      final stackTrace = StackTrace.current;
      final exception = FirebaseAuthenticationException(
        message: 'Test error',
        code: 'test-code',
        stackTrace: stackTrace,
      );
      expect(exception.message, 'Test error');
      expect(exception.code, 'test-code');
      expect(exception.stackTrace, stackTrace);
    });

    test('implements Exception', () {
      final exception = FirebaseAuthenticationException(message: 'Test');
      expect(exception, isA<Exception>());
    });

    test('toString returns formatted message', () {
      final exception = FirebaseAuthenticationException(
        message: 'Test error',
        code: 'test-code',
      );
      expect(
        exception.toString(),
        'FirebaseAuthenticationException(test-code): Test error',
      );
    });

    test('toString with null code', () {
      final exception = FirebaseAuthenticationException(message: 'Test error');
      expect(
        exception.toString(),
        'FirebaseAuthenticationException(null): Test error',
      );
    });
  });
}
