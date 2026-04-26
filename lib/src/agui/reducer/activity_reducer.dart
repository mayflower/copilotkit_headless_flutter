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
    final messageId =
        event.stringValue('messageId') ??
        event.stringValue('activityId') ??
        event.stringValue('id');
    if (messageId != null) {
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

    return current.copyWith(
      activities: _activitiesFromSnapshot(event.listValue('activities')),
    );
  }

  ThreadSession _reduceDelta(ThreadSession current, AgUiEventEnvelope event) {
    final messageId =
        event.stringValue('messageId') ??
        event.stringValue('activityId') ??
        event.stringValue('id');
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

    final delta = event.objectValue('delta') ?? event.payload;
    final activityId =
        _readString(delta['id']) ??
        _readString(delta['activityId']) ??
        _readString(delta['activity_id']);
    if (activityId == null) {
      return current;
    }

    final existing = current.activities[activityId];
    final details = <String, Object?>{...?existing?.details, ...delta};
    final updated = _activityFromDetails(
      id: activityId,
      details: details,
      existing: existing,
    );

    return current.copyWith(
      activities: <String, ActivityViewModel>{
        ...current.activities,
        activityId: updated,
      },
    );
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

Map<String, ActivityViewModel> _activitiesFromSnapshot(List<Object?>? items) {
  if (items == null) {
    return const <String, ActivityViewModel>{};
  }

  final activities = <String, ActivityViewModel>{};
  for (final item in items) {
    if (item is! Map) {
      continue;
    }

    final json = item.map((key, value) => MapEntry(key.toString(), value));
    final id =
        _readString(json['id']) ??
        _readString(json['activityId']) ??
        _readString(json['activity_id']);
    if (id == null) {
      continue;
    }

    activities[id] = _activityFromDetails(id: id, details: json);
  }
  return activities;
}

String? _readString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
