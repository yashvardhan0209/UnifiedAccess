import 'dart:io';

import '../logger.dart';

class IosValidator {
  IosValidator(this._logger);

  final Logger _logger;

  void validate({
    String? infoPlistPath,
    String? podfilePath,
    String? googleServiceInfoPlistPath,
  }) {
    _logger.section('iOS Status');

    _check('GoogleService-Info.plist', googleServiceInfoPlistPath != null);

    if (infoPlistPath != null) {
      final content = File(infoPlistPath).readAsStringSync();

      _check('UIBackgroundModes', content.contains('remote-notification'));
      _check('Facebook plist entries', content.contains('FacebookAppID'));
    } else {
      _logger.warning('ios/Runner/Info.plist not found');
    }

    if (podfilePath != null) {
      final content = File(podfilePath).readAsStringSync();
      final match =
          RegExp(r"platform\s*:ios\s*,\s*'(\d+\.?\d*)'").firstMatch(content);
      if (match != null) {
        final ver = double.tryParse(match.group(1)!) ?? 0;
        _check('Minimum iOS version >= 13.0', ver >= 13.0,
            detail: ver < 13.0
                ? 'Current: ${match.group(1)}, needs >= 13.0'
                : null);
      } else {
        _logger.warning('Could not detect platform version in Podfile');
      }
    } else {
      _logger.warning('ios/Podfile not found');
    }
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
