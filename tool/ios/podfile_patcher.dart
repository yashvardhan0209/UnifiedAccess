import 'dart:io';

import '../logger.dart';
import '../models/setup_result.dart';

class PodfilePatcher {
  PodfilePatcher(this._logger);

  final Logger _logger;

  Future<void> patch(String podfilePath, SetupResult result) async {
    final file = File(podfilePath);
    var content = file.readAsStringSync();

    final pattern = RegExp(r"platform\s*:ios\s*,\s*'(\d+\.?\d*)'");
    final match = pattern.firstMatch(content);

    if (match != null) {
      final currentVersion = double.tryParse(match.group(1)!) ?? 0;
      if (currentVersion < 13.0) {
        final backupPath = '$podfilePath.bak.unified_access';
        file.copySync(backupPath);
        result.addBackup(backupPath);

        content = content.replaceFirst(
          match.group(0)!,
          "platform :ios, '13.0'",
        );
        file.writeAsStringSync(content);
        _logger.success(
          'Updated minimum iOS version from ${match.group(1)} to 13.0',
        );
        result.addChange('ios/Podfile - Updated minimum iOS version to 13.0');
      } else {
        _logger.detail(
          'Podfile minimum iOS version is ${match.group(1)} (>= 13.0)',
        );
      }
    } else {
      _logger.warning(
        'Could not detect platform version in Podfile. '
        "Ensure it contains: platform :ios, '13.0'",
      );
    }
  }
}
