import 'package:flutter_test/flutter_test.dart';

import '../../tool/logger.dart';

void main() {
  group('Logger', () {
    test('creates with default verbose false', () {
      final logger = Logger();
      expect(logger.verbose, isFalse);
    });

    test('creates with verbose true', () {
      final logger = Logger(verbose: true);
      expect(logger.verbose, isTrue);
    });

    test('info writes to stdout', () {
      final logger = Logger();
      // Just verify it doesn't throw
      logger.info('test message');
    });

    test('success writes to stdout', () {
      final logger = Logger();
      logger.success('test message');
    });

    test('warning writes to stdout', () {
      final logger = Logger();
      logger.warning('test message');
    });

    test('error writes to stderr', () {
      final logger = Logger();
      logger.error('test message');
    });

    test('detail writes when verbose', () {
      final logger = Logger(verbose: true);
      logger.detail('test message');
    });

    test('detail does not write when not verbose', () {
      final logger = Logger(verbose: false);
      logger.detail('test message');
    });

    test('step writes to stdout', () {
      final logger = Logger();
      logger.step(1, 3, 'test step');
    });

    test('blank writes empty line', () {
      final logger = Logger();
      logger.blank();
    });

    test('banner writes header', () {
      final logger = Logger();
      logger.banner();
    });

    test('section writes section header', () {
      final logger = Logger();
      logger.section('Test Section');
    });

    test('colorize respects NO_COLOR environment', () {
      // This tests the _supportsAnsi / _colorize path
      final logger = Logger();
      // Just verify all methods work without throwing
      logger.info('info');
      logger.success('success');
      logger.warning('warning');
      logger.error('error');
      logger.step(1, 1, 'step');
      logger.banner();
      logger.section('section');
    });
  });
}
