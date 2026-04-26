import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/sse_frame_parser.dart';

void main() {
  group('SseFrameParser', () {
    test(
      'parses multi-line data fields, ignores comments, and splits on blank lines',
      () async {
        const parser = SseFrameParser();

        final frames = await parser
            .parse(
              Stream<List<int>>.fromIterable([
                utf8.encode(
                  ': keep-alive\n'
                  'id: evt-1\n'
                  'event: CUSTOM\n'
                  'data: {"name":"MOBILE_HINT",\n'
                  'data: "payload":{"hint":"focusComposer"}}\n'
                  '\n'
                  'event: RAW\n'
                  'data: {"type":"RAW","data":{"traceId":"trace-123"}}\n'
                  '\n',
                ),
              ]),
            )
            .toList();

        expect(frames, hasLength(2));
        expect(frames.first.id, 'evt-1');
        expect(frames.first.event, 'CUSTOM');
        expect(
          frames.first.data,
          '{"name":"MOBILE_HINT",\n"payload":{"hint":"focusComposer"}}',
        );
        expect(frames.last.event, 'RAW');
        expect(
          frames.last.data,
          '{"type":"RAW","data":{"traceId":"trace-123"}}',
        );
      },
    );
  });
}
