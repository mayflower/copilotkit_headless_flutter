import '../protocol/agui_event_envelope.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';

class LifecycleReducer implements AgUiReducer {
  const LifecycleReducer();

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    switch (event.type) {
      case 'RUN_STARTED':
        return current.copyWith(
          runStatus: RunStatus.running,
          activeRunId: event.stringValue('runId') ?? current.activeRunId,
          lastErrorMessage: null,
        );
      case 'RUN_FINISHED':
        return current.copyWith(
          runStatus: RunStatus.completed,
          activeRunId: null,
        );
      case 'RUN_ERROR':
        return current.copyWith(
          runStatus: RunStatus.failed,
          activeRunId: null,
          lastErrorMessage:
              event.stringValue('message') ??
              event.stringValue('detail') ??
              event.stringValue('error') ??
              current.lastErrorMessage,
        );
      default:
        return current;
    }
  }
}
