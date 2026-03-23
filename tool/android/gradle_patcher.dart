import 'dart:io';

import '../logger.dart';
import '../models/setup_config.dart';
import '../models/setup_result.dart';

class GradlePatcher {
  GradlePatcher(this._logger);

  final Logger _logger;

  Future<void> patchAppBuildGradle(
    String path,
    SetupConfig config,
    SetupResult result, {
    bool isKotlinDsl = false,
  }) async {
    final file = File(path);
    final backupPath = '$path.bak.unified_access';
    file.copySync(backupPath);
    result.addBackup(backupPath);

    var content = file.readAsStringSync();
    var modified = false;

    // Patch minSdkVersion
    content = _patchMinSdkVersion(content, isKotlinDsl, (msg) {
      modified = true;
      _logger.success(msg);
    });

    // Patch multiDexEnabled
    if (!content.contains('multiDexEnabled')) {
      content = _addMultiDex(content, isKotlinDsl);
      if (content.contains('multiDexEnabled')) {
        _logger.success('Added multiDexEnabled true');
        modified = true;
      } else {
        _logger.warning(
            'Could not add multiDexEnabled. Add it manually inside defaultConfig {}');
      }
    } else {
      _logger.detail('multiDexEnabled already present');
    }

    // Patch google-services plugin apply
    final pluginPattern = 'com.google.gms.google-services';
    if (!content.contains(pluginPattern)) {
      if (isKotlinDsl) {
        content += "\nid(\"$pluginPattern\")\n";
      } else {
        content += "\napply plugin: '$pluginPattern'\n";
      }
      _logger.success('Added google-services plugin');
      modified = true;
    } else {
      _logger.detail('google-services plugin already applied');
    }

    if (modified) {
      file.writeAsStringSync(content);
      result.addChange('android/app/build.gradle - Updated build config');
    } else {
      File(backupPath).deleteSync();
      result.backupFiles.remove(backupPath);
    }
  }

  Future<void> patchProjectBuildGradle(
    String path,
    SetupResult result, {
    bool isKotlinDsl = false,
  }) async {
    final file = File(path);
    var content = file.readAsStringSync();

    if (content.contains('com.google.gms:google-services')) {
      _logger.detail(
          'google-services classpath already present in project build.gradle');
      return;
    }

    final backupPath = '$path.bak.unified_access';
    file.copySync(backupPath);
    result.addBackup(backupPath);

    // Try to find the buildscript dependencies block
    final depsPattern =
        RegExp(r'buildscript\s*\{[^}]*dependencies\s*\{', dotAll: true);
    final match = depsPattern.firstMatch(content);

    if (match != null) {
      final insertPos = match.end;
      final classpath = isKotlinDsl
          ? '\n        classpath("com.google.gms:google-services:4.4.0")'
          : "\n        classpath 'com.google.gms:google-services:4.4.0'";
      content = content.substring(0, insertPos) +
          classpath +
          content.substring(insertPos);
      file.writeAsStringSync(content);
      _logger
          .success('Added google-services classpath to project build.gradle');
      result
          .addChange('android/build.gradle - Added google-services classpath');
    } else {
      _logger.warning(
        'Could not locate buildscript dependencies in project build.gradle. '
        'If using plugins DSL, ensure google-services is configured.',
      );
      File(backupPath).deleteSync();
      result.backupFiles.remove(backupPath);
    }
  }

  Future<void> createStringsXml(
    String projectRoot,
    SetupConfig config,
    SetupResult result,
  ) async {
    if (!config.enableFacebookLogin || config.facebookAppId == null) return;

    final dir = Directory('$projectRoot/android/app/src/main/res/values');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final file = File('${dir.path}/strings.xml');

    if (file.existsSync()) {
      var content = file.readAsStringSync();
      if (content.contains('facebook_app_id')) {
        _logger.detail('Facebook strings already present in strings.xml');
        return;
      }
      // Insert before closing </resources>
      content = content.replaceFirst(
        '</resources>',
        '    <string name="facebook_app_id">${config.facebookAppId}</string>\n'
            '    <string name="fb_login_protocol_scheme">fb${config.facebookAppId}</string>\n'
            '    <string name="facebook_client_token">${config.facebookClientToken}</string>\n'
            '</resources>',
      );
      file.writeAsStringSync(content);
    } else {
      file.writeAsStringSync(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <string name="facebook_app_id">${config.facebookAppId}</string>\n'
        '    <string name="fb_login_protocol_scheme">fb${config.facebookAppId}</string>\n'
        '    <string name="facebook_client_token">${config.facebookClientToken}</string>\n'
        '</resources>\n',
      );
    }

    _logger.success('Created/updated strings.xml with Facebook configuration');
    result.addChange(
        'android strings.xml - Added Facebook App ID and Client Token');
  }

  String _patchMinSdkVersion(
    String content,
    bool isKotlinDsl,
    void Function(String) onModified,
  ) {
    // Match patterns: minSdkVersion 16, minSdk 16, minSdk = 16, minSdkVersion = 16
    final pattern = RegExp(r'(minSdk(?:Version)?)\s*=?\s*(\d+)');
    final match = pattern.firstMatch(content);

    if (match != null) {
      final currentVersion = int.tryParse(match.group(2)!);
      if (currentVersion != null && currentVersion < 21) {
        final replacement =
            isKotlinDsl ? '${match.group(1)} = 21' : '${match.group(1)} 21';
        content = content.replaceFirst(match.group(0)!, replacement);
        onModified('Updated minSdkVersion from $currentVersion to 21');
      }
    } else if (content.contains('flutter.minSdkVersion')) {
      _logger.warning(
        'minSdkVersion is set to flutter.minSdkVersion. '
        'Ensure it resolves to >= 21 in your local.properties or gradle.properties.',
      );
    }

    return content;
  }

  String _addMultiDex(String content, bool isKotlinDsl) {
    // Find defaultConfig { ... } and insert multiDexEnabled
    final pattern = RegExp(r'defaultConfig\s*\{');
    final match = pattern.firstMatch(content);
    if (match != null) {
      final insertPos = match.end;
      final line = isKotlinDsl
          ? '\n        multiDexEnabled = true'
          : '\n        multiDexEnabled true';
      return content.substring(0, insertPos) +
          line +
          content.substring(insertPos);
    }
    return content;
  }
}
