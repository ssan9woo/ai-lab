import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_nl_verify/main.dart' as app;
import 'package:flutter_nl_verify/verify/action.dart';

import 'support/runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('action plan으로 로그인하고 체크박스를 토글한다', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final loginPlan = parseActionPlan(r'''
[
  {"action": "enterText", "target": {"by": "key", "value": "email_field"}, "value": "test@test.com"},
  {"action": "enterText", "target": {"by": "key", "value": "password_field"}, "value": "1234"},
  {"action": "tap", "target": {"by": "key", "value": "login_button"}},
  {"action": "expectVisible", "target": {"by": "key", "value": "welcome_message"}}
]
''');
    final loginResult = await runActionPlan(tester, loginPlan);

    expect(loginResult.passed, isTrue);
    expect(loginResult.steps, everyElement(isA<StepResult>()));
    expect(loginResult.steps.map((step) => step.passed), everyElement(isTrue));

    final checkboxPlan = parseActionPlan(r'''
[
  {"action": "tap", "target": {"by": "key", "value": "todo_checkbox_0"}},
  {"action": "expectChecked", "target": {"by": "key", "value": "todo_checkbox_0"}}
]
''');
    final checkboxResult = await runActionPlan(tester, checkboxPlan);

    expect(checkboxResult.passed, isTrue);
    expect(
      checkboxResult.steps.map((step) => step.passed),
      everyElement(isTrue),
    );
  });

  testWidgets('존재하지 않는 타겟은 예외 대신 실패 결과를 반환한다', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final missingTargetPlan = parseActionPlan(r'''
[
  {"action": "expectVisible", "target": {"by": "key", "value": "does_not_exist"}}
]
''');

    final result = await runActionPlan(tester, missingTargetPlan);

    expect(result.passed, isFalse);
    expect(result.steps, hasLength(1));
    expect(result.steps.single.passed, isFalse);
    expect(result.steps.single.error, isNotNull);
  });
}
