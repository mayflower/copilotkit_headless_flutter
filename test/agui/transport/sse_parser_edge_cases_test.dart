import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/sse_frame_parser.dart';

void main() {
  group('SseFrameParser edge cases', () {
    test(
      'handles UTF-8 chunks, partial frames across byte boundaries, and trailing buffers',
      () async {
        const parser = SseFrameParser();
        final rawBody =
            'event: TEXT_MESSAGE_CONTENT\n'
            'data: {"type":"TEXT_MESSAGE_CONTENT","messageId":"assistant-1","delta":"Grüße 👋"}\n'
            '\n'
            'event: RUN_FINISHED\n'
            'data: {"type":"RUN_FINISHED","runId":"run-1"}';
        final bytes = utf8.encode(rawBody);

        final frames = await parser
            .parse(
              Stream<List<int>>.fromIterable([
                bytes.sublist(0, 17),
                bytes.sublist(17, 41),
                bytes.sublist(41, 73),
                bytes.sublist(73),
              ]),
            )
            .toList();

        expect(frames, hasLength(2));
        expect(frames.first.event, 'TEXT_MESSAGE_CONTENT');
        expect(frames.first.data, contains('Grüße 👋'));
        expect(frames.last.event, 'RUN_FINISHED');
        expect(frames.last.data, '{"type":"RUN_FINISHED","runId":"run-1"}');
      },
    );
  });
}
