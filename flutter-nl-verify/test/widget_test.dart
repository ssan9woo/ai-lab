import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nl_verify/core/session/session_store.dart';
import 'package:flutter_nl_verify/features/auth/data/mock_auth_api.dart';
import 'package:flutter_nl_verify/features/auth/presentation/login_screen.dart';
import 'package:flutter_nl_verify/features/todos/presentation/main_screen.dart';

void main() {
  setUp(SessionStore.instance.clear);

  testWidgets('잘못된 계정이면 에러 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(authApi: MockAuthApi(delay: Duration.zero)),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'wrong@test.com',
    );
    await tester.enterText(find.byKey(const Key('password_field')), 'wrong');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error')), findsOneWidget);
    expect(find.text('이메일 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
  });

  testWidgets('로그인 중 로딩을 표시한 뒤 메인 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(
          authApi: MockAuthApi(delay: Duration(milliseconds: 700)),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('email_field')),
      'test@test.com',
    );
    await tester.enterText(find.byKey(const Key('password_field')), '1234');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.byKey(const Key('login_loading')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome_message')), findsOneWidget);
    expect(find.text('환영합니다, test@test.com'), findsOneWidget);
    expect(find.byKey(const Key('todo_item_0')), findsOneWidget);
    expect(SessionStore.instance.loginResponse, isNotNull);
    expect(
      SessionStore.instance.loginResponse!.accessToken.split('.'),
      hasLength(3),
    );
    expect(
      SessionStore.instance.loginResponse!.refreshToken.split('.'),
      hasLength(3),
    );
    expect(SessionStore.instance.loginResponse!.expiresIn, 3600);
  });

  testWidgets('체크박스를 누르면 완료 상태와 취소선이 반영된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainScreen(email: 'test@test.com')),
    );

    final checkboxFinder = find.byKey(const Key('todo_checkbox_0'));
    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

    await tester.tap(checkboxFinder);
    await tester.pump();

    expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
    final title = tester.widget<Text>(find.byKey(const Key('todo_title_0')));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });
}
