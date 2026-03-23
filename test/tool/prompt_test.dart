import 'package:flutter_test/flutter_test.dart';

import '../../tool/prompt.dart';

void main() {
  group('Prompt', () {
    group('with acceptAll = true', () {
      late Prompt prompt;

      setUp(() {
        prompt = const Prompt(acceptAll: true);
      });

      test('acceptAll is true', () {
        expect(prompt.acceptAll, isTrue);
      });

      test('confirm returns true', () async {
        expect(await prompt.confirm('Test?'), isTrue);
      });

      test('confirm returns true even with defaultYes false', () async {
        expect(await prompt.confirm('Test?', defaultYes: false), isTrue);
      });

      test('text returns default value', () async {
        expect(
          await prompt.text('Question', defaultValue: 'my default'),
          'my default',
        );
      });

      test('text returns empty string when no default', () async {
        expect(await prompt.text('Question'), '');
      });

      test('requiredText returns empty string', () async {
        expect(await prompt.requiredText('Question'), '');
      });
    });

    group('with acceptAll = false', () {
      test('defaults acceptAll to false', () {
        const prompt = Prompt();
        expect(prompt.acceptAll, isFalse);
      });
    });
  });
}
