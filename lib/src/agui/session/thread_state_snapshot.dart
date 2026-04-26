class ThreadStateSnapshot {
  const ThreadStateSnapshot({
    required this.fileList,
    required this.files,
    required this.todos,
    this.searchProgress,
    this.executeProgress,
    this.taskProgress,
    this.taskStatus,
    this.traceId,
    this.observationId,
  });

  factory ThreadStateSnapshot.empty() {
    return const ThreadStateSnapshot(fileList: [], files: {}, todos: []);
  }

  factory ThreadStateSnapshot.fromJson(Map<String, dynamic> json) {
    return ThreadStateSnapshot(
      fileList: _readStringList(json['file_list']),
      files: _readFileMap(json['files']),
      todos: _readTodos(json['todos']),
      searchProgress: _readOptionalString(json['search_progress']),
      executeProgress: _readOptionalString(json['execute_progress']),
      taskProgress: _readOptionalString(json['task_progress']),
      taskStatus: _readOptionalString(json['task_status']),
      traceId: _readOptionalString(json['trace_id']),
      observationId: _readOptionalString(json['observation_id']),
    );
  }

  final List<String> fileList;
  final Map<String, Object?> files;
  final List<ThreadTodoItem> todos;
  final String? searchProgress;
  final String? executeProgress;
  final String? taskProgress;
  final String? taskStatus;
  final String? traceId;
  final String? observationId;

  static Map<String, Object?> _readFileMap(Object? value) {
    if (value is! Map) {
      return const {};
    }

    return value.map((key, nestedValue) {
      return MapEntry(key.toString(), nestedValue);
    });
  }

  static String? _readOptionalString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<ThreadTodoItem> _readTodos(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (entry) => ThreadTodoItem.fromJson(
            entry.map(
              (key, nestedValue) => MapEntry(key.toString(), nestedValue),
            ),
          ),
        )
        .where((todo) => todo.content.isNotEmpty)
        .toList(growable: false);
  }
}

class ThreadTodoItem {
  const ThreadTodoItem({
    required this.content,
    required this.status,
    this.activeForm,
    this.id,
  });

  factory ThreadTodoItem.fromJson(Map<String, dynamic> json) {
    return ThreadTodoItem(
      content: _readString(json, 'content') ?? '',
      status: _readString(json, 'status') ?? 'pending',
      activeForm: _readString(json, 'activeForm'),
      id: _readString(json, 'id'),
    );
  }

  final String content;
  final String status;
  final String? activeForm;
  final String? id;

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
