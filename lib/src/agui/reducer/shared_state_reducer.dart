import '../protocol/agui_event_envelope.dart';
import '../protocol/agui_json.dart';
import '../session/shared_state_document.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';
import 'json_patch_service.dart';

class SharedStateReducer implements AgUiReducer {
  const SharedStateReducer({
    JsonPatchService patchService = const JsonPatchService(),
  }) : _patchService = patchService;

  final JsonPatchService _patchService;

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    switch (event.type) {
      case 'STATE_SNAPSHOT':
        final recoveredAt = event.receivedAt;
        return current.copyWith(
          sharedState: SharedStateDocument.fromJson(
            _snapshotPayload(event),
            capturedAt: recoveredAt,
          ),
          connectionStatus: ConnectionStatus.online,
          requiresSharedStateRecovery: false,
          sharedStateFailureReason: null,
          lastSharedStateRecoveredAt: recoveredAt,
        );
      case 'STATE_DELTA':
        if (current.requiresSharedStateRecovery) {
          return current;
        }

        final patch = event.listValue('delta') ?? event.listValue('patch');
        if (patch == null) {
          return _degraded(
            current,
            message: 'STATE_DELTA did not contain an RFC-6902 patch array.',
          );
        }

        try {
          final nextDocument = _patchService.apply(
            current.sharedState,
            patch,
            appliedAt: event.receivedAt,
          );
          return current.copyWith(sharedState: nextDocument);
        } on JsonPatchException catch (error) {
          return _degraded(current, message: error.message);
        }
      default:
        return current;
    }
  }

  ThreadSession _degraded(ThreadSession current, {required String message}) {
    return current.copyWith(
      connectionStatus: ConnectionStatus.degraded,
      requiresSharedStateRecovery: true,
      sharedStateFailureReason: message,
    );
  }

  Map<String, Object?> _snapshotPayload(AgUiEventEnvelope event) {
    return event.objectValue('snapshot') ??
        event.objectValue('state') ??
        normalizeObjectMap(event.payload);
  }
}
