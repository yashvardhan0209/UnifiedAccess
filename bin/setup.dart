import 'dart:io';

import 'package:args/args.dart';

import '../tool/cli_runner.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('check',
        help: 'Only validate current setup without modifying files',
        defaultsTo: false)
    ..addFlag('yes',
        abbr: 'y',
        help: 'Accept all defaults without prompting (enables all features)',
        defaultsTo: false)
    ..addFlag('verbose',
        abbr: 'v', help: 'Show detailed output', defaultsTo: false)
    ..addFlag('help',
        abbr: 'h', help: 'Show usage information', defaultsTo: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('Usage: dart run unified_access:setup [options]');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (results.flag('help')) {
    stdout.writeln('UnifiedAccess Setup Tool');
    stdout.writeln('');
    stdout.writeln(
        'Automates platform configuration for the unified_access package.');
    stdout.writeln('');
    stdout.writeln('Usage: dart run unified_access:setup [options]');
    stdout.writeln('');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final runner = CliRunner(
    checkOnly: results.flag('check'),
    verbose: results.flag('verbose'),
    acceptAll: results.flag('yes'),
  );

  final exitCode = await runner.run();
  exit(exitCode);
}
