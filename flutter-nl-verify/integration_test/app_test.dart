import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_nl_verify/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('로그인 후 할 일을 완료 처리할 수 있다', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@test.com',
    );
    await tester.enterText(find.byKey(const Key('password_field')), '1234');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.text('환영합니다, test@test.com'), findsOneWidget);
    expect(find.byKey(const Key('todo_list')), findsOneWidget);

    final firstCheckbox = find.byKey(const Key('todo_checkbox_0'));
    expect(tester.widget<Checkbox>(firstCheckbox).value, isFalse);

    await tester.tap(firstCheckbox);
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(firstCheckbox).value, isTrue);
    final firstTitle = tester.widget<Text>(
      find.byKey(const Key('todo_title_0')),
    );
    expect(firstTitle.style?.decoration, TextDecoration.lineThrough);
  });
}
