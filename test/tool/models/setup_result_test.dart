import 'package:flutter_test/flutter_test.dart';

import '../../../tool/models/setup_result.dart';

void main() {
  group('SetupResult', () {
    late SetupResult result;

    setUp(() {
      result = SetupResult();
    });

    test('starts with empty lists', () {
      expect(result.changesMade, isEmpty);
      expect(result.manualSteps, isEmpty);
      expect(result.backupFiles, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('addChange adds to changesMade', () {
      result.addChange('change 1');
      result.addChange('change 2');
      expect(result.changesMade, ['change 1', 'change 2']);
    });

    test('addManualStep adds to manualSteps', () {
      result.addManualStep('step 1');
      result.addManualStep('step 2');
      expect(result.manualSteps, ['step 1', 'step 2']);
    });

    test('addBackup adds to backupFiles', () {
      result.addBackup('/path/to/backup1');
      result.addBackup('/path/to/backup2');
      expect(result.backupFiles, ['/path/to/backup1', '/path/to/backup2']);
    });

    test('addWarning adds to warnings', () {
      result.addWarning('warning 1');
      result.addWarning('warning 2');
      expect(result.warnings, ['warning 1', 'warning 2']);
    });
  });
}
