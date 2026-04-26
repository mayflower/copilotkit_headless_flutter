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
      key: key,
      value: <String, Object?>{
        'description': description,
        'value': value,
        if (category != null) 'category': category,
        if (parentKey != null) 'parentKey': parentKey,
      },
    );
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
