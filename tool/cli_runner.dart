import 'dart:io';

import 'android/android_manifest_patcher.dart';
import 'android/android_validator.dart';
import 'android/gradle_patcher.dart';
import 'ios/info_plist_patcher.dart';
import 'ios/ios_validator.dart';
import 'ios/podfile_patcher.dart';
import 'logger.dart';
import 'models/setup_config.dart';
import 'models/setup_result.dart';
import 'project_detector.dart';
import 'prompt.dart';

class CliRunner {
  CliRunner({
    this.checkOnly = false,
    this.verbose = false,
    this.acceptAll = false,
  });

  final bool checkOnly;
  final bool verbose;
  final bool acceptAll;

  Future<int> run() async {
    final logger = Logger(verbose: verbose);
    final prompt = Prompt(acceptAll: acceptAll);
    final detector = ProjectDetector();

    logger.banner();

    try {
      // Detect project
      logger.info('Detecting project structure...');
      final paths = detector.detect(Directory.current.path);

      if (paths == null) {
        logger.error(
          'Not a Flutter project. Ensure pubspec.yaml exists and '
          'contains a flutter dependency.',
        );
        return 1;
      }

      logger.success('Flutter project found at: ${paths.root}');
      if (paths.hasAndroid) {
        logger.success('Android project found');
      } else {
        logger
            .warning('Android project not found (android/ directory missing)');
      }
      if (paths.hasIos) {
        logger.success('iOS project found');
      } else {
        logger.warning('iOS project not found (ios/ directory missing)');
      }

      if (!paths.hasAndroid && !paths.hasIos) {
        logger.error(
            'No platform directories found. Run "flutter create ." first.');
        return 1;
      }

      // Check-only mode
      if (checkOnly) {
        return _runCheckMode(logger, paths);
      }

      // Interactive prompts
      logger.section('Feature Configuration');

      if (acceptAll) {
        logger.info('Running with --yes: enabling all features with defaults.');
      }

      final enableGoogle = await prompt.confirm('Enable Google Sign-In?');
      final enableFacebook =
          await prompt.confirm('Enable Facebook Login?', defaultYes: false);

      String? fbAppId;
      String? fbClientToken;
      String? fbDisplayName;
      if (enableFacebook && !acceptAll) {
        fbAppId = await prompt.requiredText('Facebook App ID');
        fbClientToken = await prompt.requiredText('Facebook Client Token');
        fbDisplayName =
            await prompt.text('Facebook Display Name', defaultValue: 'My App');
      }

      final enableApple = await prompt.confirm('Enable Apple Sign-In?');
      final enablePush = await prompt.confirm('Enable Push Notifications?');

      final config = SetupConfig(
        enableGoogleSignIn: enableGoogle,
        enableFacebookLogin: enableFacebook,
        facebookAppId: fbAppId,
        facebookClientToken: fbClientToken,
        facebookDisplayName: fbDisplayName,
        enableAppleSignIn: enableApple,
        enablePushNotifications: enablePush,
      );

      final result = SetupResult();

      // Android setup
      if (paths.hasAndroid) {
        logger.section('Configuring Android');

        final manifestPatcher = AndroidManifestPatcher(logger);
        final gradlePatcher = GradlePatcher(logger);

        var step = 1;
        const totalSteps = 4;

        if (paths.androidManifest != null) {
          logger.step(step++, totalSteps, 'Patching AndroidManifest.xml...');
          await manifestPatcher.patch(paths.androidManifest!, config, result);
        }

        if (paths.androidAppBuildGradle != null) {
          logger.step(
              step++, totalSteps, 'Patching android/app/build.gradle...');
          await gradlePatcher.patchAppBuildGradle(
            paths.androidAppBuildGradle!,
            config,
            result,
            isKotlinDsl: paths.isKotlinDsl,
          );
        }

        if (paths.androidProjectBuildGradle != null) {
          logger.step(step++, totalSteps, 'Patching android/build.gradle...');
          await gradlePatcher.patchProjectBuildGradle(
            paths.androidProjectBuildGradle!,
            result,
            isKotlinDsl: paths.isKotlinDsl,
          );
        }

        if (config.enableFacebookLogin) {
          logger.step(
              step++, totalSteps, 'Configuring Facebook strings.xml...');
          await gradlePatcher.createStringsXml(paths.root, config, result);
        }

        if (paths.androidGoogleServicesJson == null) {
          result.addManualStep(
            'Download google-services.json from Firebase Console '
            'and place in android/app/ '
            '(or run "flutterfire configure" to automate this)',
          );
        }
      }

      // iOS setup
      if (paths.hasIos) {
        logger.section('Configuring iOS');

        final plistPatcher = InfoPlistPatcher(logger);
        final podfilePatcher = PodfilePatcher(logger);

        var step = 1;
        const totalSteps = 2;

        if (paths.iosInfoPlist != null) {
          logger.step(step++, totalSteps, 'Patching ios/Runner/Info.plist...');
          await plistPatcher.patch(
            paths.iosInfoPlist!,
            config,
            result,
            googleServiceInfoPlistPath: paths.iosGoogleServiceInfoPlist,
          );
        }

        if (paths.iosPodfile != null) {
          logger.step(step++, totalSteps, 'Patching ios/Podfile...');
          await podfilePatcher.patch(paths.iosPodfile!, result);
        }

        if (paths.iosGoogleServiceInfoPlist == null) {
          result.addManualStep(
            'Download GoogleService-Info.plist from Firebase Console '
            'and place in ios/Runner/ '
            '(or run "flutterfire configure" to automate this)',
          );
        }
      }

      // Common manual steps
      if (config.enablePushNotifications) {
        result.addManualStep(
            'In Xcode: Enable "Push Notifications" capability for Runner target');
        result.addManualStep(
            'In Xcode: Enable "Background Modes" capability and check "Remote notifications"');
        result.addManualStep(
            'Upload APNs authentication key to Firebase Console');
      }
      if (config.enableAppleSignIn) {
        result
            .addManualStep('In Xcode: Enable "Sign in with Apple" capability');
      }

      // Generate sample main.dart
      await _maybeGenerateSampleMain(prompt, logger, paths.root, result);

      result.addManualStep(
          'Add an Android notification icon drawable matching the defaultIcon '
          'string you pass to UnifiedNotification.init()');
      if (paths.hasIos) {
        result.addManualStep('Run: cd ios && pod install');
      }

      // Print summary
      _printSummary(logger, result);

      return 0;
    } on FileSystemException catch (e) {
      logger.error('File system error: ${e.message}');
      if (e.path != null) logger.error('Path: ${e.path}');
      return 1;
    } catch (e, stack) {
      logger.error('Unexpected error: $e');
      if (verbose) logger.detail(stack.toString());
      logger.error(
          'Please report this at https://github.com/yashvardhan0209/UnifiedAccess/issues');
      return 1;
    }
  }

  Future<void> _maybeGenerateSampleMain(
    Prompt prompt,
    Logger logger,
    String projectRoot,
    SetupResult result,
  ) async {
    final mainFile = File('$projectRoot/lib/main.dart');
    if (mainFile.existsSync()) {
      // Don't overwrite existing main.dart
      return;
    }

    final generate = await prompt.confirm(
        'Generate a sample main.dart with Firebase + Notification setup?');
    if (!generate) {
      result.addManualStep(
          'Add Firebase.initializeApp() in your main.dart before runApp()');
      return;
    }

    final libDir = Directory('$projectRoot/lib');
    if (!libDir.existsSync()) libDir.createSync(recursive: true);

    mainFile.writeAsStringSync('''import 'package:flutter/material.dart';
import 'package:unified_access/unified_access.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  final notificationService = UnifiedNotification();
  await notificationService.init(
    onOpenNotification: (message) {
      // Handle notification tap — use message data to navigate
      debugPrint('Notification tapped: \${message?.data}');
    },
    defaultIcon: 'app_icon', // Must match an Android drawable resource name
    enableCloudMessaging: true,
  );

  // Initialize authentication
  final authService = UnifiedAuthentication();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const Scaffold(
        body: Center(child: Text('UnifiedAccess Ready')),
      ),
    );
  }
}
''');

    logger.success('Generated lib/main.dart with Firebase + Notification setup');
    result.addChange('lib/main.dart - Generated sample entry point');
  }

  int _runCheckMode(Logger logger, ProjectPaths paths) {
    if (paths.hasAndroid) {
      AndroidValidator(logger).validate(
        manifestPath: paths.androidManifest,
        appBuildGradlePath: paths.androidAppBuildGradle,
        googleServicesJsonPath: paths.androidGoogleServicesJson,
      );
    }

    if (paths.hasIos) {
      IosValidator(logger).validate(
        infoPlistPath: paths.iosInfoPlist,
        podfilePath: paths.iosPodfile,
        googleServiceInfoPlistPath: paths.iosGoogleServiceInfoPlist,
      );
    }

    logger.blank();
    logger.info(
        'Run "dart run unified_access:setup" to fix issues automatically.');
    return 0;
  }

  void _printSummary(Logger logger, SetupResult result) {
    logger.section('Summary');

    if (result.changesMade.isNotEmpty) {
      stdout.writeln('Changes made:');
      for (final change in result.changesMade) {
        logger.success(change);
      }
    } else {
      logger.info('No changes were needed - everything is already configured.');
    }

    if (result.warnings.isNotEmpty) {
      logger.blank();
      stdout.writeln('Warnings:');
      for (final warning in result.warnings) {
        logger.warning(warning);
      }
    }

    if (result.manualSteps.isNotEmpty) {
      logger.blank();
      stdout.writeln('Remaining manual steps:');
      for (var i = 0; i < result.manualSteps.length; i++) {
        stdout.writeln('  ${i + 1}. ${result.manualSteps[i]}');
      }
    }

    if (result.backupFiles.isNotEmpty) {
      logger.blank();
      stdout.writeln('Backup files created:');
      for (final backup in result.backupFiles) {
        stdout.writeln('  $backup');
      }
    }

    logger.blank();
  }
}
