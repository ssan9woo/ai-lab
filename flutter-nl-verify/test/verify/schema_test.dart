import 'package:flutter_nl_verify/verify/schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wraps the array schema for Claude without mutating the source', () {
    final source = <String, dynamic>{
      r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      r'$id': 'example',
      'title': 'Actions',
      'type': 'array',
      'items': <String, dynamic>{r'$ref': r'#/$defs/action'},
      r'$defs': <String, dynamic>{
        'action': <String, dynamic>{'type': 'object'},
      },
    };

    final wrapped = buildClaudeJsonSchema(source);
    final actions =
        (wrapped['properties'] as Map<String, dynamic>)['actions']
            as Map<String, dynamic>;

    expect(wrapped['type'], 'object');
    expect(wrapped['required'], <String>['actions']);
    expect(wrapped['additionalProperties'], isFalse);
    expect(wrapped[r'$defs'], same(source[r'$defs']));
    expect(actions['type'], 'array');
    expect(actions['items'], source['items']);
    expect(actions, isNot(contains(r'$schema')));
    expect(actions, isNot(contains(r'$id')));
    expect(actions, isNot(contains(r'$defs')));
    expect(source, contains(r'$schema'));
    expect(source, contains(r'$id'));
    expect(source, contains(r'$defs'));
  });

  test('rejects a schema whose top-level type is not array', () {
    expect(
      () => buildClaudeJsonSchema(<String, dynamic>{'type': 'object'}),
      throwsFormatException,
    );
  });
}
