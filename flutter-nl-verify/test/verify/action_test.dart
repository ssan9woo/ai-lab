import 'dart:convert';

import 'package:flutter_nl_verify/verify/action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const keyTarget = ActionTarget(by: 'key', value: 'login_button');

  group('action JSON round trips', () {
    final cases = <VerifyAction>[
      const EnterTextAction(
        target: ActionTarget(by: 'key', value: 'email_field'),
        value: 'test@test.com',
      ),
      const TapAction(target: keyTarget),
      const ExpectVisibleAction(
        target: ActionTarget(by: 'text', value: 'Welcome'),
      ),
      const ExpectCheckedAction(target: keyTarget, expected: true),
      const ExpectCheckedAction(target: keyTarget, expected: false),
      const ExpectTextAction(target: keyTarget, value: 'Log in'),
    ];

    for (final action in cases) {
      test(action.runtimeType.toString(), () {
        final json = action.toJson();
        final parsed = VerifyAction.fromJson(json);

        expect(parsed.runtimeType, action.runtimeType);
        expect(parsed.toJson(), json);
      });
    }
  });

  test('parses the complete example action plan', () {
    const source = '''
      [
        {"action":"enterText","target":{"by":"key","value":"email_field"},"value":"test@test.com"},
        {"action":"enterText","target":{"by":"key","value":"password_field"},"value":"1234"},
        {"action":"tap","target":{"by":"key","value":"login_button"}},
        {"action":"expectVisible","target":{"by":"key","value":"welcome_message"}}
      ]
    ''';

    final actions = parseActionPlan(source);

    expect(actions, hasLength(4));
    expect(actions[0], isA<EnterTextAction>());
    expect((actions[0] as EnterTextAction).value, 'test@test.com');
    expect(actions[1], isA<EnterTextAction>());
    expect(actions[2], isA<TapAction>());
    expect(actions[3], isA<ExpectVisibleAction>());
    expect(actions[3].target.value, 'welcome_message');
    expect(jsonEncode(actions), contains('welcome_message'));
  });

  test('rejects an unknown action', () {
    expect(
      () => parseActionPlan(
        '[{"action":"swipe","target":{"by":"key","value":"list"}}]',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Unknown action "swipe"'),
        ),
      ),
    );
  });

  test('rejects a missing required field', () {
    expect(
      () => parseActionPlan('[{"action":"enterText","value":"hello"}]'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('enterText.target must be a JSON object'),
        ),
      ),
    );
  });

  test('rejects an invalid target strategy', () {
    expect(
      () => VerifyAction.fromJson({
        'action': 'tap',
        'target': {'by': 'type', 'value': 'Button'},
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
