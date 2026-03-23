import 'dart:io';

class Prompt {
  const Prompt({this.acceptAll = false});

  final bool acceptAll;

  bool get _isInteractive => stdin.hasTerminal && !acceptAll;

  Future<bool> confirm(String question, {bool defaultYes = true}) async {
    if (!_isInteractive) return acceptAll ? true : defaultYes;

    final hint = defaultYes ? 'Y/n' : 'y/N';
    stdout.write('? $question [$hint] ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';

    if (input.isEmpty) return defaultYes;
    return input == 'y' || input == 'yes';
  }

  Future<String> text(String question, {String? defaultValue}) async {
    if (!_isInteractive) return defaultValue ?? '';

    final hint = defaultValue != null ? ' [$defaultValue]' : '';
    stdout.write('? $question$hint: ');
    final input = stdin.readLineSync()?.trim() ?? '';

    if (input.isEmpty && defaultValue != null) return defaultValue;
    return input;
  }

  Future<String> requiredText(String question) async {
    if (acceptAll) return '';
    if (!stdin.hasTerminal) {
      throw StateError(
        'Cannot prompt for required input in non-interactive mode',
      );
    }

    while (true) {
      stdout.write('? $question: ');
      final input = stdin.readLineSync()?.trim() ?? '';
      if (input.isNotEmpty) return input;
      stdout.writeln('  (This field is required)');
    }
  }
}
