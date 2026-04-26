import '../protocol/agui_event_envelope.dart';
import '../session/thread_session.dart';

abstract interface class AgUiReducer {
  const AgUiReducer();

  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event);
}
