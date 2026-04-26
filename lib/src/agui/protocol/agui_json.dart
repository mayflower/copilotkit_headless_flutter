Map<String, Object?> normalizeObjectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value.map(
      (key, nestedValue) => MapEntry(key, normalizeJsonValue(nestedValue)),
    );
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(key.toString(), normalizeJsonValue(nestedValue)),
    );
  }
  return const <String, Object?>{};
}

List<Object?> normalizeObjectList(Object? value) {
  if (value is List<Object?>) {
    return value.map(normalizeJsonValue).toList(growable: false);
  }
  if (value is List) {
    return value.map(normalizeJsonValue).toList(growable: false);
  }
  return const <Object?>[];
}

Object? normalizeJsonValue(Object? value) {
  if (value is Map) {
    return normalizeObjectMap(value);
  }
  if (value is List) {
    return normalizeObjectList(value);
  }
  return value;
}

String? normalizeString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
