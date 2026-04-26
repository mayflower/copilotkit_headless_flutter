import '../protocol/agui_event_envelope.dart';
import '../protocol/agui_event.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';

class DebugReducer implements AgUiReducer {
  const DebugReducer();

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    final isInspectable =
        event.decodeErrorMessage != null ||
        event.type == 'RAW' ||
        event.type == 'CUSTOM' ||
        event.event is UnknownAgUiEvent;
    if (!isInspectable) {
      return current;
    }

    return current.copyWith(
      debugEvents: [
        ...current.debugEvents,
        DebugEventViewModel(
          type: event.type ?? 'UNKNOWN',
          rawPayload: event.rawPayload,
          receivedAt: event.receivedAt,
          payload: event.payload,
          decodeErrorMessage: event.decodeErrorMessage,
        ),
      ],
    );
  }
}
