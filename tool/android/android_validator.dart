import 'dart:io';

import '../logger.dart';

class AndroidValidator {
  AndroidValidator(this._logger);

  final Logger _logger;

  void validate({
    String? manifestPath,
    String? appBuildGradlePath,
    String? googleServicesJsonPath,
  }) {
    _logger.section('Android Status');

    if (manifestPath != null) {
      final content = File(manifestPath).readAsStringSync();

      _check('INTERNET permission',
          content.contains('android.permission.INTERNET'));
      _check('POST_NOTIFICATIONS permission',
          content.contains('android.permission.POST_NOTIFICATIONS'));
      _check('Notification channel metadata',
          content.contains('default_notification_channel_id'));
    } else {
      _logger.warning('AndroidManifest.xml not found');
    }

    if (appBuildGradlePath != null) {
      final content = File(appBuildGradlePath).readAsStringSync();

      // Check minSdkVersion
      final sdkMatch =
          RegExp(r'minSdk(?:Version)?\s*=?\s*(\d+)').firstMatch(content);
      if (sdkMatch != null) {
        final ver = int.tryParse(sdkMatch.group(1)!) ?? 0;
        _check('minSdkVersion >= 21', ver >= 21,
            detail: ver < 21 ? 'Current: $ver, needs >= 21' : null);
      } else if (content.contains('flutter.minSdkVersion')) {
        _logger.warning(
            'minSdkVersion uses flutter.minSdkVersion - verify it resolves to >= 21');
      }

      _check('google-services plugin',
          content.contains('com.google.gms.google-services'));
    } else {
      _logger.warning('android/app/build.gradle not found');
    }

    _check('google-services.json', googleServicesJsonPath != null);
  }

  void _check(String item, bool isConfigured, {String? detail}) {
    if (isConfigured) {
      _logger.success('$item: Present');
    } else {
      final suffix = detail != null ? ' ($detail)' : '';
      _logger.warning('$item: Missing$suffix');
    }
  }
}
