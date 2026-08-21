import 'dart:convert';

/// Identifies a widget by its key or visible text.
final class ActionTarget {
  const ActionTarget({required this.by, required this.value});

  factory ActionTarget.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {'by', 'value'}, 'target');

    final by = _requireString(json, 'by', 'target');
    if (by != 'key' && by != 'text') {
      throw FormatException(
        'Invalid target.by "$by". Expected "key" or "text".',
      );
    }

    return ActionTarget(by: by, value: _requireString(json, 'value', 'target'));
  }

  final String by;
  final String value;

  Map<String, dynamic> toJson() => {'by': by, 'value': value};
}

sealed class VerifyAction {
  const VerifyAction();

  factory VerifyAction.fromJson(Map<String, dynamic> json) {
    final action = _requireString(json, 'action', 'action');
    return switch (action) {
      'enterText' => EnterTextAction.fromJson(json),
      'tap' => TapAction.fromJson(json),
      'expectVisible' => ExpectVisibleAction.fromJson(json),
      'expectChecked' => ExpectCheckedAction.fromJson(json, expected: true),
      'expectUnchecked' => ExpectCheckedAction.fromJson(json, expected: false),
      'expectText' => ExpectTextAction.fromJson(json),
      _ => throw FormatException('Unknown action "$action".'),
    };
  }

  ActionTarget get target;

  Map<String, dynamic> toJson();
}

final class EnterTextAction extends VerifyAction {
  const EnterTextAction({required this.target, required this.value});

  factory EnterTextAction.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {'action', 'target', 'value'}, 'enterText');
    return EnterTextAction(
      target: _requireTarget(json, 'enterText'),
      value: _requireString(json, 'value', 'enterText'),
    );
  }

  @override
  final ActionTarget target;
  final String value;

  @override
  Map<String, dynamic> toJson() => {
    'action': 'enterText',
    'target': target.toJson(),
    'value': value,
  };
}

final class TapAction extends VerifyAction {
  const TapAction({required this.target});

  factory TapAction.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {'action', 'target'}, 'tap');
    return TapAction(target: _requireTarget(json, 'tap'));
  }

  @override
  final ActionTarget target;

  @override
  Map<String, dynamic> toJson() => {'action': 'tap', 'target': target.toJson()};
}

final class ExpectVisibleAction extends VerifyAction {
  const ExpectVisibleAction({required this.target});

  factory ExpectVisibleAction.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {'action', 'target'}, 'expectVisible');
    return ExpectVisibleAction(target: _requireTarget(json, 'expectVisible'));
  }

  @override
  final ActionTarget target;

  @override
  Map<String, dynamic> toJson() => {
    'action': 'expectVisible',
    'target': target.toJson(),
  };
}

/// Represents both `expectChecked` and `expectUnchecked` wire actions.
final class ExpectCheckedAction extends VerifyAction {
  const ExpectCheckedAction({required this.target, required this.expected});

  factory ExpectCheckedAction.fromJson(
    Map<String, dynamic> json, {
    required bool expected,
  }) {
    final action = expected ? 'expectChecked' : 'expectUnchecked';
    _requireOnlyKeys(json, const {'action', 'target'}, action);
    return ExpectCheckedAction(
      target: _requireTarget(json, action),
      expected: expected,
    );
  }

  @override
  final ActionTarget target;
  final bool expected;

  @override
  Map<String, dynamic> toJson() => {
    'action': expected ? 'expectChecked' : 'expectUnchecked',
    'target': target.toJson(),
  };
}

final class ExpectTextAction extends VerifyAction {
  const ExpectTextAction({required this.target, required this.value});

  factory ExpectTextAction.fromJson(Map<String, dynamic> json) {
    _requireOnlyKeys(json, const {'action', 'target', 'value'}, 'expectText');
    return ExpectTextAction(
      target: _requireTarget(json, 'expectText'),
      value: _requireString(json, 'value', 'expectText'),
    );
  }

  @override
  final ActionTarget target;
  final String value;

  @override
  Map<String, dynamic> toJson() => {
    'action': 'expectText',
    'target': target.toJson(),
    'value': value,
  };
}

/// Parses a complete action plan from a JSON array string.
List<VerifyAction> parseActionPlan(String source) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException catch (error) {
    throw FormatException('Invalid action plan JSON: ${error.message}');
  }

  if (decoded is! List<dynamic>) {
    throw const FormatException('Action plan must be a JSON array.');
  }

  return List<VerifyAction>.unmodifiable(
    decoded.indexed.map((entry) {
      final (index, value) = entry;
      if (value is! Map<String, dynamic>) {
        throw FormatException('Action at index $index must be a JSON object.');
      }
      try {
        return VerifyAction.fromJson(value);
      } on FormatException catch (error) {
        throw FormatException(
          'Invalid action at index $index: ${error.message}',
        );
      }
    }),
  );
}

ActionTarget _requireTarget(Map<String, dynamic> json, String context) {
  final value = json['target'];
  if (value is! Map<String, dynamic>) {
    throw FormatException('$context.target must be a JSON object.');
  }
  return ActionTarget.fromJson(value);
}

String _requireString(Map<String, dynamic> json, String key, String context) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing required field "$key" in $context.');
  }
  final value = json[key];
  if (value is! String) {
    throw FormatException('$context.$key must be a string.');
  }
  return value;
}

void _requireOnlyKeys(
  Map<String, dynamic> json,
  Set<String> allowed,
  String context,
) {
  final unexpected = json.keys.where((key) => !allowed.contains(key)).toList();
  if (unexpected.isNotEmpty) {
    throw FormatException(
      'Unexpected field(s) in $context: ${unexpected.join(', ')}.',
    );
  }
}
