import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agui_event_decoder.dart';

void main() {
  group('decodeAgUiEventStream', () {
    test('decodes AG-UI envelopes from SSE frames', () async {
      final events = await decodeAgUiEventStream(
        Stream<List<int>>.fromIterable([
          utf8.encode(
            'event: STATE_SNAPSHOT\n'
            'data: {"type":"STATE_SNAPSHOT","snapshot":{"file_list":["/tmp/report.md"]}}\n'
            '\n'
            'event: MESSAGES_SNAPSHOT\n'
            'data: {"messages":[{"id":"m1","role":"assistant","content":"Hydrated"}]}\n'
            '\n',
          ),
        ]),
      ).toList();

      expect(events, hasLength(2));
      expect(events.first.type, 'STATE_SNAPSHOT');
      expect(events.first.objectValue('snapshot')?['file_list'], [
        '/tmp/report.md',
      ]);
      expect(events.last.type, 'MESSAGES_SNAPSHOT');
      expect(events.last.listValue('messages'), isNotNull);
    });

    test('flushes a trailing frame without a final blank line', () async {
      final events = await decodeAgUiEventStream(
        Stream<List<int>>.fromIterable([
          utf8.encode('event: TEXT_MESSAGE_CONTENT\n'),
          utf8.encode('data: {"messageId":"msg-1","delta":"Hello"}'),
        ]),
      ).toList();

      expect(events, hasLength(1));
      expect(events.single.type, 'TEXT_MESSAGE_CONTENT');
      expect(events.single.stringValue('messageId'), 'msg-1');
      expect(events.single.stringValue('delta'), 'Hello');
    });
  });
}
