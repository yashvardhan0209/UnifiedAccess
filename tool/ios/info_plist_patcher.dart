import 'dart:io';

import 'package:xml/xml.dart';

import '../logger.dart';
import '../models/setup_config.dart';
import '../models/setup_result.dart';

class InfoPlistPatcher {
  InfoPlistPatcher(this._logger);

  final Logger _logger;

  Future<void> patch(
    String plistPath,
    SetupConfig config,
    SetupResult result, {
    String? googleServiceInfoPlistPath,
  }) async {
    final file = File(plistPath);
    final backupPath = '$plistPath.bak.unified_access';
    file.copySync(backupPath);
    result.addBackup(backupPath);

    final content = file.readAsStringSync();
    final document = XmlDocument.parse(content);
    final plist = document.rootElement;
    final dict = plist.findElements('dict').first;

    var modified = false;

    // Add UIBackgroundModes for push notifications
    if (config.enablePushNotifications) {
      if (!_hasPlistKey(dict, 'UIBackgroundModes')) {
        _addPlistArray(dict, 'UIBackgroundModes', [
          'fetch',
          'remote-notification',
        ]);
        _logger.success('Added UIBackgroundModes (remote-notification, fetch)');
        modified = true;
      } else {
        // Check if remote-notification is in the existing array
        final array = _getPlistValue(dict, 'UIBackgroundModes');
        if (array != null && array.localName == 'array') {
          final values = array
              .findElements('string')
              .map((e) => e.innerText)
              .toSet();
          if (!values.contains('remote-notification')) {
            array.children.add(
              XmlElement(XmlName('string'), [], [
                XmlText('remote-notification'),
              ]),
            );
            _logger.success('Added remote-notification to UIBackgroundModes');
            modified = true;
          }
          if (!values.contains('fetch')) {
            array.children.add(
              XmlElement(XmlName('string'), [], [XmlText('fetch')]),
            );
            _logger.success('Added fetch to UIBackgroundModes');
            modified = true;
          }
          if (!modified) {
            _logger.detail('UIBackgroundModes already configured');
          }
        }
      }
    }

    // Google Sign-In URL scheme
    if (config.enableGoogleSignIn) {
      final reversedClientId = _extractReversedClientId(
        googleServiceInfoPlistPath,
      );
      if (reversedClientId != null) {
        if (!_hasUrlScheme(dict, reversedClientId)) {
          _addUrlScheme(dict, reversedClientId);
          _logger.success('Added Google Sign-In URL scheme');
          modified = true;
        } else {
          _logger.detail('Google Sign-In URL scheme already present');
        }
      } else {
        _logger.warning(
          'GoogleService-Info.plist not found. '
          'Add the REVERSED_CLIENT_ID URL scheme manually after downloading it.',
        );
        result.addManualStep(
          'Add reversed client ID from GoogleService-Info.plist to '
          'ios/Runner/Info.plist as a URL scheme (for Google Sign-In)',
        );
      }
    }

    // Facebook Login
    if (config.enableFacebookLogin && config.facebookAppId != null) {
      if (!_hasPlistKey(dict, 'FacebookAppID')) {
        _addPlistString(dict, 'FacebookAppID', config.facebookAppId!);
        _addPlistString(
          dict,
          'FacebookClientToken',
          config.facebookClientToken ?? '',
        );
        _addPlistString(
          dict,
          'FacebookDisplayName',
          config.facebookDisplayName ?? '',
        );

        // Add fb URL scheme
        _addUrlScheme(dict, 'fb${config.facebookAppId}');

        // Add LSApplicationQueriesSchemes
        if (!_hasPlistKey(dict, 'LSApplicationQueriesSchemes')) {
          _addPlistArray(dict, 'LSApplicationQueriesSchemes', [
            'fbapi',
            'fb-messenger-share-api',
          ]);
        }

        _logger.success('Added Facebook configuration to Info.plist');
        modified = true;
      } else {
        _logger.detail('Facebook configuration already present in Info.plist');
      }
    }

    if (modified) {
      file.writeAsStringSync(document.toXmlString(pretty: true, indent: '\t'));
      result.addChange('ios/Runner/Info.plist - Updated configuration');
    } else {
      File(backupPath).deleteSync();
      result.backupFiles.remove(backupPath);
    }
  }

  String? _extractReversedClientId(String? googleServiceInfoPlistPath) {
    if (googleServiceInfoPlistPath == null) return null;
    final file = File(googleServiceInfoPlistPath);
    if (!file.existsSync()) return null;

    try {
      final doc = XmlDocument.parse(file.readAsStringSync());
      final dict = doc.rootElement.findElements('dict').first;
      final value = _getPlistValue(dict, 'REVERSED_CLIENT_ID');
      return value?.innerText;
    } catch (_) {
      return null;
    }
  }

  bool _hasPlistKey(XmlElement dict, String keyName) {
    return dict.findElements('key').any((e) => e.innerText == keyName);
  }

  XmlElement? _getPlistValue(XmlElement dict, String keyName) {
    final children = dict.childElements.toList();
    for (var i = 0; i < children.length - 1; i++) {
      if (children[i].localName == 'key' && children[i].innerText == keyName) {
        return children[i + 1];
      }
    }
    return null;
  }

  void _addPlistString(XmlElement dict, String key, String value) {
    dict.children.add(XmlElement(XmlName('key'), [], [XmlText(key)]));
    dict.children.add(XmlElement(XmlName('string'), [], [XmlText(value)]));
  }

  void _addPlistArray(XmlElement dict, String key, List<String> values) {
    dict.children.add(XmlElement(XmlName('key'), [], [XmlText(key)]));
    dict.children.add(
      XmlElement(
        XmlName('array'),
        [],
        values.map((v) => XmlElement(XmlName('string'), [], [XmlText(v)])),
      ),
    );
  }

  bool _hasUrlScheme(XmlElement dict, String scheme) {
    final urlTypes = _getPlistValue(dict, 'CFBundleURLTypes');
    if (urlTypes == null) return false;

    // Search all dicts in the array for the scheme
    for (final urlDict in urlTypes.findElements('dict')) {
      final schemesArray = _getPlistValue(urlDict, 'CFBundleURLSchemes');
      if (schemesArray != null) {
        for (final s in schemesArray.findElements('string')) {
          if (s.innerText == scheme) return true;
        }
      }
    }
    return false;
  }

  void _addUrlScheme(XmlElement dict, String scheme) {
    // Check if CFBundleURLTypes already exists
    var urlTypes = _getPlistValue(dict, 'CFBundleURLTypes');

    if (urlTypes == null) {
      // Create CFBundleURLTypes array
      dict.children.add(
        XmlElement(XmlName('key'), [], [XmlText('CFBundleURLTypes')]),
      );
      urlTypes = XmlElement(XmlName('array'));
      dict.children.add(urlTypes);
    }

    // Add a new dict with the scheme
    final schemeDict = XmlElement(XmlName('dict'), [], [
      XmlElement(XmlName('key'), [], [XmlText('CFBundleTypeRole')]),
      XmlElement(XmlName('string'), [], [XmlText('Editor')]),
      XmlElement(XmlName('key'), [], [XmlText('CFBundleURLSchemes')]),
      XmlElement(XmlName('array'), [], [
        XmlElement(XmlName('string'), [], [XmlText(scheme)]),
      ]),
    ]);

    urlTypes.children.add(schemeDict);
  }
}
