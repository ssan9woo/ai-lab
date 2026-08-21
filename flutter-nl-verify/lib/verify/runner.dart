import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'action.dart';

class StepResult {
  const StepResult({
    required this.action,
    required this.passed,
    required this.error,
    required this.duration,
  });

  final VerifyAction action;
  final bool passed;
  final String? error;
  final Duration duration;
}

class RunResult {
  const RunResult({required this.steps});

  final List<StepResult> steps;

  bool get passed => steps.every((step) => step.passed);
}

Future<RunResult> runActionPlan(
  WidgetTester tester,
  List<VerifyAction> actions,
) async {
  final steps = <StepResult>[];

  for (final action in actions) {
    final stopwatch = Stopwatch()..start();
    String? error;

    try {
      final finder = _finderFor(action.target);
      await _runAction(tester, action, finder);
    } catch (exception) {
      error = exception.toString();
    } finally {
      stopwatch.stop();
    }

    steps.add(
      StepResult(
        action: action,
        passed: error == null,
        error: error,
        duration: stopwatch.elapsed,
      ),
    );
  }

  return RunResult(steps: List<StepResult>.unmodifiable(steps));
}

Finder _finderFor(ActionTarget target) {
  return switch (target.by) {
    'key' => find.byKey(Key(target.value)),
    'text' => find.text(target.value),
    _ => throw ArgumentError.value(
      target.by,
      'target.by',
      'Expected "key" or "text"',
    ),
  };
}

Future<void> _runAction(
  WidgetTester tester,
  VerifyAction action,
  Finder finder,
) async {
  switch (action) {
    case EnterTextAction():
      _requireExactlyOne(finder, action.target);
      await tester.enterText(finder, action.value);
      await tester.pumpAndSettle();
    case TapAction():
      _requireExactlyOne(finder, action.target);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    case ExpectVisibleAction():
      if (finder.evaluate().isEmpty) {
        throw StateError('No widget found for ${_describe(action.target)}.');
      }
    case ExpectCheckedAction():
      _requireExactlyOne(finder, action.target);
      final widget = tester.widget(finder);
      if (widget is! Checkbox) {
        throw StateError(
          'Widget for ${_describe(action.target)} is ${widget.runtimeType}, '
          'not Checkbox.',
        );
      }
      if (widget.value != action.expected) {
        throw StateError(
          'Checkbox for ${_describe(action.target)} has value '
          '${widget.value}; expected ${action.expected}.',
        );
      }
    case ExpectTextAction():
      _requireExactlyOne(finder, action.target);
      final widget = tester.widget(finder);
      if (widget is! Text) {
        throw StateError(
          'Widget for ${_describe(action.target)} is ${widget.runtimeType}, '
          'not Text.',
        );
      }
      if (widget.data != action.value) {
        throw StateError(
          'Text for ${_describe(action.target)} has data ${widget.data}; '
          'expected ${action.value}.',
        );
      }
  }
}

void _requireExactlyOne(Finder finder, ActionTarget target) {
  final count = finder.evaluate().length;
  if (count != 1) {
    throw StateError(
      'Expected exactly one widget for ${_describe(target)}, found $count.',
    );
  }
}

String _describe(ActionTarget target) =>
    'target(by: ${target.by}, value: ${target.value})';
