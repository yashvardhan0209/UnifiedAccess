import 'dart:io';

class Logger {
  Logger({this.verbose = false});

  final bool verbose;

  static const _reset = '\x1B[0m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';
  static const _cyan = '\x1B[36m';
  static const _bold = '\x1B[1m';

  bool get _supportsAnsi =>
      stdout.supportsAnsiEscapes &&
      !Platform.environment.containsKey('NO_COLOR');

  String _colorize(String text, String color) =>
      _supportsAnsi ? '$color$text$_reset' : text;

  void info(String msg) => stdout.writeln(_colorize('[*] $msg', _cyan));

  void success(String msg) => stdout.writeln(_colorize('[OK] $msg', _green));

  void warning(String msg) => stdout.writeln(_colorize('[!!] $msg', _yellow));

  void error(String msg) => stderr.writeln(_colorize('[ERROR] $msg', _red));

  void detail(String msg) {
    if (verbose) stdout.writeln('    $msg');
  }

  void step(int current, int total, String msg) =>
      stdout.writeln(_colorize('[$current/$total] $msg', _bold));

  void blank() => stdout.writeln();

  void banner() {
    blank();
    stdout.writeln(_colorize('  UnifiedAccess Setup Tool', _bold));
    stdout.writeln('  Automates platform configuration for unified_access');
    blank();
  }

  void section(String title) {
    blank();
    stdout.writeln(_colorize('--- $title ---', _bold));
    blank();
  }
}
