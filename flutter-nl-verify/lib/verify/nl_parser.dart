import 'dart:convert';
import 'dart:io';

import 'action.dart';
import 'schema.dart';

const String widgetVocabulary = '''
사용 가능한 Flutter 위젯 key와 의미:

[로그인 화면]
- email_field: 이메일 입력
- password_field: 비밀번호 입력
- login_button: 로그인 버튼
- login_error: 에러 메시지
- login_loading: 로딩 인디케이터

[메인 화면 (할 일 목록)]
- welcome_message: 환영 메시지
- todo_list: 리스트 전체
- todo_item_\$index: N번째 할 일 항목 (index는 0부터 시작)
- todo_checkbox_\$index: N번째 체크박스 (index는 0부터 시작)
- todo_title_\$index: N번째 할 일 텍스트 (index는 0부터 시작)

[유효 로그인 계정]
- 이메일: test@test.com
- 비밀번호: 1234
''';

final class NlParseException implements Exception {
  const NlParseException(this.message);

  final String message;

  @override
  String toString() => 'NlParseException: $message';
}

Future<List<VerifyAction>> parseNaturalLanguage(String instruction) async {
  final actionSchema = await loadActionDslSchema();
  final claudeSchema = buildClaudeJsonSchema(actionSchema);
  final prompt =
      '''
다음 자연어 지시를 주어진 JSON Schema에 맞는 UI action 목록으로 변환하세요.
target은 가능하면 by를 "key"로 하고 아래 vocabulary의 정확한 key를 사용하세요.
설명이나 마크다운 없이 구조화된 결과만 생성하세요.

$widgetVocabulary
[사용자 지시]
$instruction
''';

  final ProcessResult result;
  try {
    result = await Process.run('claude', <String>[
      '-p',
      prompt,
      '--output-format=json',
      '--json-schema',
      jsonEncode(claudeSchema),
      '--disallowedTools',
      'Bash,Read,Write,Edit,WebSearch,WebFetch',
    ]);
  } on ProcessException catch (error) {
    throw NlParseException(
      'Claude Code CLI executable "claude" could not be started: '
      '${error.message}',
    );
  }

  final stdoutText = result.stdout.toString().trim();
  final stderrText = result.stderr.toString().trim();
  if (result.exitCode != 0) {
    final detail = stderrText.isNotEmpty ? stderrText : stdoutText;
    throw NlParseException(
      'Claude Code CLI exited with code ${result.exitCode}'
      '${detail.isEmpty ? '.' : ': $detail'}',
    );
  }

  final dynamic response;
  try {
    response = jsonDecode(stdoutText);
  } on FormatException catch (error) {
    throw NlParseException(
      'Claude Code CLI stdout was not valid JSON: ${error.message}. '
      'Output: ${stdoutText.isEmpty ? '(empty)' : stdoutText}',
    );
  }
  if (response is! Map<String, dynamic>) {
    throw const NlParseException(
      'Claude Code CLI response must be a JSON object.',
    );
  }
  if (response['is_error'] == true) {
    throw NlParseException(
      'Claude Code CLI reported an error: ${response['result'] ?? '(no message)'}',
    );
  }

  final structuredOutput = response['structured_output'];
  if (structuredOutput is! Map<String, dynamic>) {
    throw const NlParseException(
      'Claude Code CLI response is missing structured_output.',
    );
  }
  final actions = structuredOutput['actions'];
  if (actions == null) {
    throw const NlParseException(
      'Claude Code CLI structured_output is missing actions.',
    );
  }

  try {
    return parseActionPlan(jsonEncode(actions));
  } on FormatException catch (error) {
    throw NlParseException('Claude returned an invalid action plan: $error');
  }
}
