import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_event.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_event_envelope.dart';

import 'agui_fixture_loader.dart';

void main() {
  group('AgUiEventEnvelope', () {
    test(
      'preserves the raw payload and receive timestamp for decoded events',
      () async {
        final rawPayload = await loadAgUiFixtureText('run_started.json');
        final receivedAt = DateTime.utc(2026, 4, 18, 12, 0, 0);

        final envelope = AgUiEventEnvelope.fromRawPayload(
          rawPayload: rawPayload,
          receivedAt: receivedAt,
        );

        expect(envelope.rawPayload, rawPayload);
        expect(envelope.receivedAt, receivedAt);
        expect(envelope.decodeErrorMessage, isNull);
        expect(envelope.event, isA<RunStartedEvent>());
      },
    );

    test('captures decode-failure metadata without losing the raw payload', () {
      final receivedAt = DateTime.utc(2026, 4, 18, 12, 5, 0);
      const rawPayload = '{"type":"RUN_STARTED","threadId":';

      final envelope = AgUiEventEnvelope.fromRawPayload(
        rawPayload: rawPayload,
        receivedAt: receivedAt,
      );

      expect(envelope.rawPayload, rawPayload);
      expect(envelope.receivedAt, receivedAt);
      expect(envelope.event, isNull);
      expect(envelope.decodeErrorMessage, isNotNull);
    });
  });
}
