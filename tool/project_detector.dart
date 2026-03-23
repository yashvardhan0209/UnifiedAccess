import 'dart:io';

class ProjectPaths {
  ProjectPaths({
    required this.root,
    this.androidManifest,
    this.androidAppBuildGradle,
    this.androidProjectBuildGradle,
    this.iosInfoPlist,
    this.iosPodfile,
    this.iosGoogleServiceInfoPlist,
    this.androidGoogleServicesJson,
    this.androidStringsXml,
    this.isKotlinDsl = false,
  });

  final String root;
  final String? androidManifest;
  final String? androidAppBuildGradle;
  final String? androidProjectBuildGradle;
  final String? iosInfoPlist;
  final String? iosPodfile;
  final String? iosGoogleServiceInfoPlist;
  final String? androidGoogleServicesJson;
  final String? androidStringsXml;
  final bool isKotlinDsl;

  bool get hasAndroid => androidManifest != null;
  bool get hasIos => iosInfoPlist != null;
}

class ProjectDetector {
  String? _findFile(String path) => File(path).existsSync() ? path : null;

  ProjectPaths? detect(String rootPath) {
    final pubspecFile = File('$rootPath/pubspec.yaml');
    if (!pubspecFile.existsSync()) return null;

    final pubspec = pubspecFile.readAsStringSync();
    if (!pubspec.contains('flutter:')) return null;

    // Detect Kotlin DSL vs Groovy
    final isKotlinDsl = File(
      '$rootPath/android/app/build.gradle.kts',
    ).existsSync();
    final gradleExt = isKotlinDsl ? '.gradle.kts' : '.gradle';

    return ProjectPaths(
      root: rootPath,
      androidManifest: _findFile(
        '$rootPath/android/app/src/main/AndroidManifest.xml',
      ),
      androidAppBuildGradle: _findFile('$rootPath/android/app/build$gradleExt'),
      androidProjectBuildGradle: _findFile('$rootPath/android/build$gradleExt'),
      iosInfoPlist: _findFile('$rootPath/ios/Runner/Info.plist'),
      iosPodfile: _findFile('$rootPath/ios/Podfile'),
      iosGoogleServiceInfoPlist: _findFile(
        '$rootPath/ios/Runner/GoogleService-Info.plist',
      ),
      androidGoogleServicesJson: _findFile(
        '$rootPath/android/app/google-services.json',
      ),
      androidStringsXml: _findFile(
        '$rootPath/android/app/src/main/res/values/strings.xml',
      ),
      isKotlinDsl: isKotlinDsl,
    );
  }
}
