import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/reducer/lifecycle_reducer.dart';
import 'package:copilotkit_headless_flutter/src/agui/session/thread_session.dart';

import '../test_helpers/envelope_factory.dart';

void main() {
  group('LifecycleReducer', () {
    test('transitions run status and captures errors', () {
      const reducer = LifecycleReducer();
      var session = ThreadSession.initial('thread-123');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'RUN_STARTED',
          'threadId': 'thread-123',
          'runId': 'run-1',
        }),
      );

      expect(session.runStatus, RunStatus.running);
      expect(session.activeRunId, 'run-1');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'RUN_ERROR',
          'threadId': 'thread-123',
          'runId': 'run-1',
          'message': 'The run failed.',
        }),
      );

      expect(session.runStatus, RunStatus.failed);
      expect(session.activeRunId, isNull);
      expect(session.lastErrorMessage, 'The run failed.');

      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'RUN_STARTED',
          'threadId': 'thread-123',
          'runId': 'run-2',
        }),
      );
      session = reducer.reduce(
        session,
        envelopeFromJson(<String, Object?>{
          'type': 'RUN_FINISHED',
          'threadId': 'thread-123',
          'runId': 'run-2',
        }),
      );

      expect(session.runStatus, RunStatus.completed);
      expect(session.activeRunId, isNull);
    });
  });
}
