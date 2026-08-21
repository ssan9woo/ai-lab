import 'dart:convert';
import 'dart:io';

const String actionDslSchemaPath = 'docs/action_dsl.schema.json';

/// Reads the action DSL array schema from disk.
Future<Map<String, dynamic>> loadActionDslSchema({
  String path = actionDslSchemaPath,
}) async {
  final source = await File(path).readAsString();
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Action DSL schema must be a JSON object.');
  }
  return decoded;
}

/// Wraps the array action schema in the object shape required by Claude CLI.
///
/// `$schema` and `$id` are deliberately omitted because Claude CLI resolves
/// schemas offline. `$defs` is lifted to the wrapper root so local `$ref`s
/// continue to resolve.
Map<String, dynamic> buildClaudeJsonSchema(
  Map<String, dynamic> actionArraySchema,
) {
  if (actionArraySchema['type'] != 'array') {
    throw const FormatException(
      'Action DSL schema must have top-level type "array".',
    );
  }

  final actionsSchema = Map<String, dynamic>.from(actionArraySchema)
    ..remove(r'$schema')
    ..remove(r'$id')
    ..remove(r'$defs');
  final definitions = actionArraySchema[r'$defs'];

  return <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{'actions': actionsSchema},
    'required': <String>['actions'],
    'additionalProperties': false,
    r'$defs': ?definitions,
  };
}
