import '../protocol/agui_event_envelope.dart';
import '../protocol/agui_json.dart';
import '../session/shared_state_document.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';
import 'json_patch_service.dart';

class ActivityReducer implements AgUiReducer {
  const ActivityReducer({
    JsonPatchService patchService = const JsonPatchService(),
  }) : _patchService = patchService;

  final JsonPatchService _patchService;

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    switch (event.type) {
      case 'ACTIVITY_SNAPSHOT':
        return _reduceSnapshot(current, event);
      case 'ACTIVITY_DELTA':
        return _reduceDelta(current, event);
      default:
        return current;
    }
  }

  ThreadSession _reduceSnapshot(
    ThreadSession current,
    AgUiEventEnvelope event,
  ) {
    final messageId = event.stringValue('messageId');
    if (messageId == null) {
      return current;
    }

    final content = event.objectValue('content') ?? event.payload;
    final existing = current.activities[messageId];
    final replace = event.payload['replace'] != false;
    final details = replace
        ? normalizeObjectMap(content)
        : <String, Object?>{
            ...?existing?.details,
            ...normalizeObjectMap(content),
          };
    final updated = _activityFromDetails(
      id: messageId,
      activityType: event.stringValue('activityType'),
      details: details,
      existing: existing,
    );
    return current.copyWith(
      activities: <String, ActivityViewModel>{
        ...current.activities,
        messageId: updated,
      },
    );
  }

  ThreadSession _reduceDelta(ThreadSession current, AgUiEventEnvelope event) {
    final messageId = event.stringValue('messageId');
    final patch = event.listValue('patch');
    if (messageId != null && patch != null) {
      final existing = current.activities[messageId];
      final base = existing?.details ?? const <String, Object?>{};
      try {
        final patched = _patchService.apply(
          SharedStateDocument(data: base),
          patch,
          appliedAt: event.receivedAt,
        );
        final updated = _activityFromDetails(
          id: messageId,
          activityType: event.stringValue('activityType'),
          details: patched.data,
          existing: existing,
        );
        return current.copyWith(
          activities: <String, ActivityViewModel>{
            ...current.activities,
            messageId: updated,
          },
        );
      } on JsonPatchException {
        return current;
      }
    }

    return current;
  }
}

ActivityViewModel _activityFromDetails({
  required String id,
  required Map<String, Object?> details,
  String? activityType,
  ActivityViewModel? existing,
}) {
  return ActivityViewModel(
    id: id,
    label:
        _readString(details['label']) ??
        _readString(details['title']) ??
        _readString(details['name']) ??
        activityType ??
        existing?.label ??
        id,
    status:
        _readString(details['status']) ??
        existing?.status ??
        _readString(details['state']) ??
        'unknown',
    summary: _readString(details['summary']) ?? existing?.summary,
    details: details,
  );
}

String? _readString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
