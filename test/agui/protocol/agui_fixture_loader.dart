import 'dart:convert';
import 'dart:io';

final Directory _projectRoot = Directory.current;

Future<Map<String, Object?>> loadAgUiFixture(String fileName) async {
  final path = '${_projectRoot.path}/test/fixtures/agui/$fileName';
  final raw = await File(path).readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, Object?>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw StateError('Fixture $fileName must decode to a JSON object.');
}

Future<String> loadAgUiFixtureText(String fileName) {
  final path = '${_projectRoot.path}/test/fixtures/agui/$fileName';
  return File(path).readAsString();
}
