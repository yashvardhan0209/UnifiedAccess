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

  /// Error message when email is already registered
  static const String emailAlreadyInUse =
      'This email is already registered. Please sign in or use a different email.';

  /// Error message for weak password during registration
  static const String weakPassword =
      'Password is too weak. Please use a stronger password.';

  /// Error message when too many requests are sent
  static const String tooManyRequests =
      'Too many requests. Please try again later.';

  /// Error message for network failure
  static const String networkRequestFailed =
      'Network error. Please check your internet connection and try again.';

  /// Error message when recent login is required for sensitive operations
  static const String requiresRecentLogin =
      'This operation requires recent login. Please sign in again and retry.';

  /// Error message when account exists with a different credential
  static const String accountExistsWithDifferentCredential =
      'An account already exists with the same email but a different sign-in method.';

  /// Error message for unknown or unhandled errors
  static const String unknownError =
      'Unknown Error! Please contact admin for details.';
}

/// FirebaseAuthenticationException class
///
/// Custom exception class for handling Firebase authentication-related errors.
/// It stores the error [message], a machine-readable [code] for programmatic
/// error handling, and an optional [stackTrace] for debugging.
class FirebaseAuthenticationException implements Exception {
  /// Constructor to initialize the exception with a [message], optional [code], and optional [stackTrace]
  FirebaseAuthenticationException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  /// Error message describing the exception
  final String message;

  /// Machine-readable error code for programmatic handling (e.g., 'user-not-found')
  final String? code;

  /// Optional stack trace for debugging purposes
  final StackTrace? stackTrace;

  /// Overrides the `toString` method to provide a formatted exception message and stack trace
  @override
  String toString() => 'FirebaseAuthenticationException($code): $message';
}
