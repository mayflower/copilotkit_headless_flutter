import 'dart:convert';

import '../agui/protocol/run_agent_input.dart';

class CopilotReadable {
  const CopilotReadable({
    required this.key,
    required this.description,
    required this.value,
    this.available = true,
    this.category,
    this.parentKey,
  });

  final String key;
  final String description;
  final Object? value;
  final bool available;
  final String? category;
  final String? parentKey;

  AgUiContextEntry toContextEntry() {
    return AgUiContextEntry(
      description: [
        description,
        if (category != null) 'Category: $category',
        if (parentKey != null) 'Parent: $parentKey',
        'Key: $key',
      ].join('\n'),
      value: _contextValue(value),
    );
  }
}

String _contextValue(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value;
  }
  try {
    return jsonEncode(value);
  } on Object {
    return value.toString();
  }
}

class CopilotReadableRegistry {
  CopilotReadableRegistry({Iterable<CopilotReadable> entries = const []})
    : _entries = <String, CopilotReadable>{
        for (final entry in entries) entry.key: entry,
      };

  final Map<String, CopilotReadable> _entries;

  List<CopilotReadable> get entries =>
      List<CopilotReadable>.unmodifiable(_entries.values);

  void set(CopilotReadable entry) {
    _entries[entry.key] = entry;
  }

  bool remove(String key) => _entries.remove(key) != null;

  void clear() {
    _entries.clear();
  }

  List<AgUiContextEntry> toContextEntries() {
    return _entries.values
        .where((entry) => entry.available)
        .map((entry) => entry.toContextEntry())
        .toList(growable: false);
  }
}
