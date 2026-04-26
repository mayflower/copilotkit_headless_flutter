import '../protocol/agui_event_envelope.dart';
import '../reducer/activity_reducer.dart';
import '../reducer/agui_reducer.dart';
import '../reducer/debug_reducer.dart';
import '../reducer/shared_state_reducer.dart';
import '../reducer/lifecycle_reducer.dart';
import '../reducer/message_reducer.dart';
import '../reducer/reasoning_reducer.dart';
import '../reducer/tool_call_reducer.dart';
import 'thread_session.dart';

class ThreadSessionController {
  ThreadSessionController({List<AgUiReducer>? reducers})
    : _reducers = List<AgUiReducer>.unmodifiable(
        reducers ?? defaultAgUiReducers,
      );

  final List<AgUiReducer> _reducers;

  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    var next = current.copyWith(
      connectionStatus: ConnectionStatus.online,
      eventLog: [...current.eventLog, event],
      lastEventAt: event.receivedAt,
    );
    for (final reducer in _reducers) {
      next = reducer.reduce(next, event);
    }
    return next;
  }

  Stream<ThreadSession> bind({
    required ThreadSession initialSession,
    required Stream<AgUiEventEnvelope> events,
  }) async* {
    var current = initialSession;
    await for (final event in events) {
      current = reduce(current, event);
      yield current;
    }
  }
}

typedef AgentController = ThreadSessionController;

const List<AgUiReducer> defaultAgUiReducers = <AgUiReducer>[
  LifecycleReducer(),
  MessageReducer(),
  ToolCallReducer(),
  ActivityReducer(),
  ReasoningReducer(),
  SharedStateReducer(),
  DebugReducer(),
];
