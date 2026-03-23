import 'dart:io';

import 'package:xml/xml.dart';

import '../logger.dart';
import '../models/setup_config.dart';
import '../models/setup_result.dart';

class AndroidManifestPatcher {
  AndroidManifestPatcher(this._logger);

  final Logger _logger;

  static const _requiredPermissions = [
    'android.permission.INTERNET',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.VIBRATE',
    'android.permission.RECEIVE_BOOT_COMPLETED',
  ];

  static const _fcmChannelId =
      'com.google.firebase.messaging.default_notification_channel_id';

  Future<void> patch(
    String manifestPath,
    SetupConfig config,
    SetupResult result,
  ) async {
    final file = File(manifestPath);
    final backupPath = '$manifestPath.bak.unified_access';
    file.copySync(backupPath);
    result.addBackup(backupPath);

    final content = file.readAsStringSync();
    final document = XmlDocument.parse(content);
    final manifest = document.rootElement;
    final application = manifest.findElements('application').first;

    var modified = false;

    // Add missing permissions
    for (final perm in _requiredPermissions) {
      if (!_hasPermission(manifest, perm)) {
        _addPermission(manifest, perm);
        _logger.success('Added $perm permission');
        modified = true;
      } else {
        _logger.detail('$perm permission already present');
      }
    }

    // Add notification channel metadata
    if (!_hasMetaData(application, _fcmChannelId)) {
      _addMetaData(application, _fcmChannelId, _fcmChannelId);
      _logger.success('Added FCM notification channel metadata');
      modified = true;
    } else {
      _logger.detail('FCM notification channel metadata already present');
    }

    // Facebook configuration
    if (config.enableFacebookLogin) {
      if (!_hasMetaData(application, 'com.facebook.sdk.ApplicationId')) {
        _addMetaData(
          application,
          'com.facebook.sdk.ApplicationId',
          '@string/facebook_app_id',
        );
        _addMetaData(
          application,
          'com.facebook.sdk.ClientToken',
          '@string/facebook_client_token',
        );
        _addFacebookActivities(application);
        _logger.success('Added Facebook configuration to AndroidManifest');
        modified = true;
      } else {
        _logger.detail('Facebook configuration already present');
      }
    }

    if (modified) {
      file.writeAsStringSync(
        document.toXmlString(pretty: true, indent: '    '),
      );
      result.addChange('AndroidManifest.xml - Added permissions and metadata');
    } else {
      // Remove unnecessary backup
      File(backupPath).deleteSync();
      result.backupFiles.remove(backupPath);
    }
  }

  bool _hasPermission(XmlElement manifest, String permissionName) {
    return manifest
        .findElements('uses-permission')
        .any((e) => e.getAttribute('android:name') == permissionName);
  }

  void _addPermission(XmlElement manifest, String permissionName) {
    final firstApplication = manifest.findElements('application').first;
    final index = manifest.children.indexOf(firstApplication);

    final elem = XmlElement(XmlName('uses-permission'), [
      XmlAttribute(XmlName('android:name'), permissionName),
    ]);

    manifest.children.insert(index, elem);
  }

  bool _hasMetaData(XmlElement application, String name) {
    return application
        .findElements('meta-data')
        .any((e) => e.getAttribute('android:name') == name);
  }

  void _addMetaData(XmlElement application, String name, String value) {
    application.children.add(
      XmlElement(XmlName('meta-data'), [
        XmlAttribute(XmlName('android:name'), name),
        XmlAttribute(XmlName('android:value'), value),
      ]),
    );
  }

  void _addFacebookActivities(XmlElement application) {
    // FacebookActivity
    application.children.add(
      XmlElement(XmlName('activity'), [
        XmlAttribute(XmlName('android:name'), 'com.facebook.FacebookActivity'),
        XmlAttribute(
          XmlName('android:configChanges'),
          'keyboard|keyboardHidden|screenLayout|screenSize|orientation',
        ),
        XmlAttribute(XmlName('android:label'), '@string/app_name'),
      ]),
    );

    // CustomTabActivity with intent-filter
    final intentFilter = XmlElement(XmlName('intent-filter'), [], [
      XmlElement(XmlName('action'), [
        XmlAttribute(XmlName('android:name'), 'android.intent.action.VIEW'),
      ]),
      XmlElement(XmlName('category'), [
        XmlAttribute(
          XmlName('android:name'),
          'android.intent.category.DEFAULT',
        ),
      ]),
      XmlElement(XmlName('category'), [
        XmlAttribute(
          XmlName('android:name'),
          'android.intent.category.BROWSABLE',
        ),
      ]),
      XmlElement(XmlName('data'), [
        XmlAttribute(
          XmlName('android:scheme'),
          '@string/fb_login_protocol_scheme',
        ),
      ]),
    ]);

    application.children.add(
      XmlElement(
        XmlName('activity'),
        [
          XmlAttribute(
            XmlName('android:name'),
            'com.facebook.CustomTabActivity',
          ),
          XmlAttribute(XmlName('android:exported'), 'true'),
        ],
        [intentFilter],
      ),
    );
  }
}
