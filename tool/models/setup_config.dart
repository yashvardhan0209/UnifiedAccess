class SetupConfig {
  SetupConfig({
    this.enableGoogleSignIn = false,
    this.enableFacebookLogin = false,
    this.facebookAppId,
    this.facebookClientToken,
    this.facebookDisplayName,
    this.enableAppleSignIn = false,
    this.enablePushNotifications = false,
  });

  final bool enableGoogleSignIn;
  final bool enableFacebookLogin;
  final String? facebookAppId;
  final String? facebookClientToken;
  final String? facebookDisplayName;
  final bool enableAppleSignIn;
  final bool enablePushNotifications;
}
