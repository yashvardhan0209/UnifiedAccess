/// FirebaseExceptionMessage class
///
/// Contains static constant strings for common error messages related to
/// Firebase authentication exceptions. These messages are displayed to users
/// when specific authentication errors occur.
class FirebaseExceptionMessage {
  /// Error message for when the user aborts the sign-in process
  static const String abortedByUser = 'Sign in aborted by user';

  /// Error message for invalid email input
  static const String invalidEmailId =
      'Invalid email id. Please enter a valid email Id.';

  /// Error message for incorrect password
  static const String wrongPassword =
      'Wrong password. Please enter the correct password.';

  /// Error message for invalid phone number input
  static const String invalidPhoneNumber =
      'Invalid phone number. Please input a valid phone number.';

  /// Error message when a user is not found in the system
  static const String userNotFound =
      'This user does not exist. Contact admin for registration.';

  /// Error message for phone number verification failure
  static const String verificationFailed =
      'Phone number verification failed. Please try again.';

  /// Error message for an invalid OTP
  static const String invalidOTP =
      'Invalid OTP entered. Please enter a 6 digit OTP.';

  /// Error message for invalid credentials during authentication
  static const String invalidCredential =
      'The given credential is malformed. Please try again.';

  /// Error message when an operation is not allowed by Firebase
  static const String operationNotAllowed =
      'This operation is not allowed. Please contact admin for details.';

  /// Error message when the user account is disabled
  static const String userDisabled =
      'This user has been disabled. Please contact admin for details.';

  /// Error message for an invalid verification code during login
  static const String invalidVerificationCode =
      'Unable to verify user. Please login again.';

  /// Error message for an invalid verification ID during login
  static const String invalidVerificationId =
      'Unable to verify user. Please login again.';

  /// Error message for unknown or unhandled errors
  static const String unknownError =
      'Unknown Error! Please contact admin for details.';
}

/// FirebaseAuthenticationException class
///
/// Custom exception class for handling Firebase authentication-related errors.
/// It stores the error [message] and an optional [stackTrace] for debugging.
class FirebaseAuthenticationException implements Exception {
  /// Constructor to initialize the exception with a [message] and optional [stackTrace]
  FirebaseAuthenticationException({
    required this.message,
    this.stackTrace,
  });

  /// Error message describing the exception
  final String message;

  /// Optional stack trace for debugging purposes
  final StackTrace? stackTrace;

  /// Overrides the `toString` method to provide a formatted exception message and stack trace
  @override
  String toString() => 'Message - $message \n StackTrace - $stackTrace';
}
