import '../protocol/agui_json.dart';
import '../session/shared_state_document.dart';

class JsonPatchException implements Exception {
  const JsonPatchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JsonPatchService {
  const JsonPatchService();

  SharedStateDocument apply(
    SharedStateDocument document,
    List<Object?> patch, {
    DateTime? appliedAt,
  }) {
    Object? root = normalizeJsonValue(document.data);
    for (final operationValue in patch) {
      final operation = normalizeObjectMap(operationValue);
      final op = normalizeString(operation['op']);
      final path = operation['path'];
      if (op == null || path is! String) {
        throw const JsonPatchException(
          'JSON Patch operations require string op and path fields.',
        );
      }

      root = _applyOperation(
        root,
        op: op,
        path: path,
        value: operation['value'],
        from: operation['from'],
      );
    }

    if (root is! Map) {
      throw const JsonPatchException(
        'Shared state root must remain a JSON object after patch application.',
      );
    }

    return document.copyWith(
      data: normalizeObjectMap(root),
      lastDeltaAt: appliedAt,
    );
  }
}

Object? _applyOperation(
  Object? root, {
  required String op,
  required String path,
  Object? value,
  Object? from,
}) {
  final tokens = _decodePointer(path);
  return switch (op) {
    'add' => _applyAdd(root, tokens: tokens, value: normalizeJsonValue(value)),
    'replace' => _applyReplace(
      root,
      tokens: tokens,
      value: normalizeJsonValue(value),
    ),
    'remove' => _applyRemove(root, tokens: tokens),
    'move' => _applyMove(root, from: from, tokens: tokens),
    'copy' => _applyCopy(root, from: from, tokens: tokens),
    'test' => _applyTest(root, tokens: tokens, value: value),
    _ => throw JsonPatchException('Unsupported JSON Patch operation "$op".'),
  };
}

Object? _applyMove(
  Object? root, {
  required Object? from,
  required List<String> tokens,
}) {
  if (from is! String) {
    throw const JsonPatchException('JSON Patch move requires a string from.');
  }

  final fromTokens = _decodePointer(from);
  final value = normalizeJsonValue(_getNode(root, fromTokens));
  final removed = _applyRemove(root, tokens: fromTokens);
  return _applyAdd(removed, tokens: tokens, value: value);
}

Object? _applyCopy(
  Object? root, {
  required Object? from,
  required List<String> tokens,
}) {
  if (from is! String) {
    throw const JsonPatchException('JSON Patch copy requires a string from.');
  }

  final value = normalizeJsonValue(_getNode(root, _decodePointer(from)));
  return _applyAdd(root, tokens: tokens, value: value);
}

Object? _applyTest(
  Object? root, {
  required List<String> tokens,
  required Object? value,
}) {
  final current = normalizeJsonValue(_getNode(root, tokens));
  final expected = normalizeJsonValue(value);
  if (!_jsonEquals(current, expected)) {
    throw JsonPatchException(
      'JSON Patch test failed at "${_formatPath(tokens)}".',
    );
  }
  return root;
}

List<String> _decodePointer(String path) {
  if (path.isEmpty) {
    return const <String>[];
  }
  if (!path.startsWith('/')) {
    throw JsonPatchException('Invalid JSON Pointer "$path".');
  }
  return path
      .substring(1)
      .split('/')
      .map((segment) => segment.replaceAll('~1', '/').replaceAll('~0', '~'))
      .toList(growable: false);
}

Object? _applyAdd(
  Object? root, {
  required List<String> tokens,
  required Object? value,
}) {
  if (tokens.isEmpty) {
    return value;
  }

  final parentTokens = tokens.take(tokens.length - 1).toList();
  final parent = _getNode(root, parentTokens, requestedTokens: tokens);
  final key = tokens.last;
  if (parent is Map) {
    return _replaceNode(
      root,
      parentTokens: parentTokens,
      newNode: <String, Object?>{
        ...normalizeObjectMap(parent),
        key: normalizeJsonValue(value),
      },
    );
  }
  if (parent is List) {
    final list = normalizeObjectList(parent);
    final updated = [...list];
    if (key == '-') {
      updated.add(normalizeJsonValue(value));
    } else {
      final index = _parseListIndex(
        key,
        allowEnd: true,
        length: updated.length,
      );
      updated.insert(index, normalizeJsonValue(value));
    }
    return _replaceNode(root, parentTokens: parentTokens, newNode: updated);
  }

  throw JsonPatchException(
    'Cannot add at "$_formatPath(tokens)" on non-container.',
  );
}

Object? _applyReplace(
  Object? root, {
  required List<String> tokens,
  required Object? value,
}) {
  if (tokens.isEmpty) {
    return value;
  }

  final parentTokens = tokens.take(tokens.length - 1).toList();
  final parent = _getNode(root, parentTokens, requestedTokens: tokens);
  final key = tokens.last;
  if (parent is Map) {
    final map = normalizeObjectMap(parent);
    if (!map.containsKey(key)) {
      throw JsonPatchException(
        'Cannot replace missing path "${_formatPath(tokens)}".',
      );
    }
    return _replaceNode(
      root,
      parentTokens: parentTokens,
      newNode: <String, Object?>{...map, key: normalizeJsonValue(value)},
    );
  }
  if (parent is List) {
    final list = normalizeObjectList(parent);
    final index = _parseListIndex(key, allowEnd: false, length: list.length);
    final updated = [...list]..[index] = normalizeJsonValue(value);
    return _replaceNode(root, parentTokens: parentTokens, newNode: updated);
  }

  throw JsonPatchException(
    'Cannot replace at "${_formatPath(tokens)}" on non-container.',
  );
}

Object? _applyRemove(Object? root, {required List<String> tokens}) {
  if (tokens.isEmpty) {
    throw const JsonPatchException('Cannot remove the shared-state root.');
  }

  final parentTokens = tokens.take(tokens.length - 1).toList();
  final parent = _getNode(root, parentTokens, requestedTokens: tokens);
  final key = tokens.last;
  if (parent is Map) {
    final map = normalizeObjectMap(parent);
    if (!map.containsKey(key)) {
      throw JsonPatchException(
        'Cannot remove missing path "${_formatPath(tokens)}".',
      );
    }
    final updated = <String, Object?>{...map}..remove(key);
    return _replaceNode(root, parentTokens: parentTokens, newNode: updated);
  }
  if (parent is List) {
    final list = normalizeObjectList(parent);
    final index = _parseListIndex(key, allowEnd: false, length: list.length);
    final updated = [...list]..removeAt(index);
    return _replaceNode(root, parentTokens: parentTokens, newNode: updated);
  }

  throw JsonPatchException('Cannot remove at "${_formatPath(tokens)}".');
}

Object? _getNode(
  Object? root,
  List<String> tokens, {
  List<String>? requestedTokens,
}) {
  final reportedTokens = requestedTokens ?? tokens;
  var current = root;
  for (final token in tokens) {
    if (current is Map) {
      final map = normalizeObjectMap(current);
      if (!map.containsKey(token)) {
        throw JsonPatchException(
          'Missing path "${_formatPath(reportedTokens)}".',
        );
      }
      current = map[token];
      continue;
    }

    if (current is List) {
      final list = normalizeObjectList(current);
      final index = _parseListIndex(
        token,
        allowEnd: false,
        length: list.length,
      );
      current = list[index];
      continue;
    }

    throw JsonPatchException(
      'Cannot traverse into non-container at "${_formatPath(reportedTokens)}".',
    );
  }
  return current;
}

Object? _replaceNode(
  Object? root, {
  required List<String> parentTokens,
  required Object? newNode,
}) {
  if (parentTokens.isEmpty) {
    return newNode;
  }

  final grandParentTokens = parentTokens.take(parentTokens.length - 1).toList();
  final grandParent = _getNode(root, grandParentTokens);
  final token = parentTokens.last;
  if (grandParent is Map) {
    final map = normalizeObjectMap(grandParent);
    return _replaceNode(
      root,
      parentTokens: grandParentTokens,
      newNode: <String, Object?>{...map, token: newNode},
    );
  }
  if (grandParent is List) {
    final list = normalizeObjectList(grandParent);
    final index = _parseListIndex(token, allowEnd: false, length: list.length);
    final updated = [...list]..[index] = newNode;
    return _replaceNode(
      root,
      parentTokens: grandParentTokens,
      newNode: updated,
    );
  }
  throw JsonPatchException(
    'Cannot write parent path "${_formatPath(parentTokens)}".',
  );
}

int _parseListIndex(
  String token, {
  required bool allowEnd,
  required int length,
}) {
  final index = int.tryParse(token);
  if (index == null) {
    throw JsonPatchException('Invalid list index "$token".');
  }
  final max = allowEnd ? length : length - 1;
  if (index < 0 || index > max) {
    throw JsonPatchException('List index "$token" is out of bounds.');
  }
  return index;
}

String _formatPath(List<String> tokens) {
  if (tokens.isEmpty) {
    return '/';
  }
  return '/${tokens.join('/')}';
}

bool _jsonEquals(Object? left, Object? right) {
  if (left is Map || right is Map) {
    if (left is! Map || right is! Map) {
      return false;
    }
    final leftMap = normalizeObjectMap(left);
    final rightMap = normalizeObjectMap(right);
    if (leftMap.length != rightMap.length) {
      return false;
    }
    for (final entry in leftMap.entries) {
      if (!rightMap.containsKey(entry.key) ||
          !_jsonEquals(entry.value, rightMap[entry.key])) {
        return false;
      }
    }
    return true;
  }

  if (left is List || right is List) {
    if (left is! List || right is! List) {
      return false;
    }
    final leftList = normalizeObjectList(left);
    final rightList = normalizeObjectList(right);
    if (leftList.length != rightList.length) {
      return false;
    }
    for (var index = 0; index < leftList.length; index += 1) {
      if (!_jsonEquals(leftList[index], rightList[index])) {
        return false;
      }
    }
    return true;
  }

  return left == right;
}
