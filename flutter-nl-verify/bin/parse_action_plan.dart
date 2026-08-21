import 'dart:convert';
import 'dart:io';

import 'package:flutter_nl_verify/verify/nl_parser.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/parse_action_plan.dart "<natural language instruction>"',
    );
    exitCode = 64;
    return;
  }

  try {
    final actions = await parseNaturalLanguage(arguments.join(' '));
    const encoder = JsonEncoder.withIndent('  ');
    stdout.writeln(
      encoder.convert(actions.map((action) => action.toJson()).toList()),
    );
  } on Object catch (error) {
    stderr.writeln('Failed to parse action plan: $error');
    exitCode = 1;
  }
}
