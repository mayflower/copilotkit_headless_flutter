import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:copilotkit_headless_flutter/src/agui/protocol/connect_agent_input.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_event.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/run_agent_input.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agent_transport.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agui_http_transport.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agui_transport_config.dart';

void main() {
  group('AgUiHttpTransport', () {
    test('POSTs RunAgentInput and streams decoded envelopes', () async {
      final client = _RecordingStreamingClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://stack.example.com/api/client/copilotkit/agent/maistack_agent/run',
        );
        expect(request.headers['accept'], 'text/event-stream');
        expect(request.headers['authorization'], 'Bearer test-id-token');

        final body =
            jsonDecode((request as http.Request).body) as Map<String, Object?>;
        expect(body['threadId'], 'thread-123');
        expect(body['runId'], 'run-123');
        final messages = body['messages'] as List<Object?>;
        expect(messages.single, isA<Map<String, Object?>>());
        expect(
          (messages.single as Map<String, Object?>)['content'],
          'Hello mobile edge.',
        );

        return _sseResponse(
          'event: RUN_STARTED\n'
          'data: {"runId":"run-123","threadId":"thread-123"}\n'
          '\n',
        );
      });

      final transport = AgUiHttpTransport(
        httpClient: client,
        config: AgUiTransportConfig(
          baseUrl: Uri.parse('https://stack.example.com'),
          authHeaderProvider: () async => const {
            'Authorization': 'Bearer test-id-token',
          },
        ),
      );

      final events = await transport
          .run(
            RunAgentInput.userTextTurn(
              threadId: 'thread-123',
              runId: 'run-123',
              messageId: 'message-1',
              text: 'Hello mobile edge.',
            ),
          )
          .toList();

      expect(events, hasLength(1));
      expect(events.single.type, 'RUN_STARTED');
      expect(
        events.single.rawPayload,
        '{"runId":"run-123","threadId":"thread-123"}',
      );
      expect(events.single.event, isA<RunStartedEvent>());
    });

    test('supports cancellation', () async {
      final streamController = StreamController<List<int>>();
      final client = _RecordingStreamingClient((request) async {
        return http.StreamedResponse(
          streamController.stream,
          200,
          headers: const {'content-type': 'text/event-stream'},
        );
      });

      final transport = AgUiHttpTransport(
        httpClient: client,
        config: AgUiTransportConfig(
          baseUrl: Uri.parse('https://stack.example.com'),
          authHeaderProvider: () async => const {
            'Authorization': 'Bearer test-id-token',
          },
        ),
      );
      final cancelToken = AgUiTransportCancellationToken();
      final events = <String?>[];

      final done = Completer<void>();
      transport
          .run(
            RunAgentInput.userTextTurn(
              threadId: 'thread-123',
              runId: 'run-123',
              messageId: 'message-1',
              text: 'Cancel me',
            ),
            cancelToken: cancelToken,
          )
          .listen(
            (event) => events.add(event.type),
            onDone: done.complete,
            onError: done.completeError,
          );

      streamController.add(
        utf8.encode(
          'event: RUN_STARTED\n'
          'data: {"runId":"run-123","threadId":"thread-123"}\n'
          '\n',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      cancelToken.cancel();
      streamController.add(
        utf8.encode(
          'event: RUN_FINISHED\n'
          'data: {"runId":"run-123"}\n'
          '\n',
        ),
      );
      await streamController.close();
      await done.future;

      expect(events, ['RUN_STARTED']);
    });

    test(
      'POSTs ConnectAgentInput and preserves backend thread aliases',
      () async {
        final client = _RecordingStreamingClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://stack.example.com/api/client/copilotkit/agent/maistack_agent/connect',
          );
          expect(request.headers['accept'], 'text/event-stream');
          expect(request.headers['authorization'], 'Bearer test-id-token');

          final body =
              jsonDecode((request as http.Request).body)
                  as Map<String, Object?>;
          expect(body['threadId'], 'thread-123');
          expect(body['thread_id'], 'thread-123');

          return _sseResponse(
            'event: MESSAGES_SNAPSHOT\n'
            'data: {"type":"MESSAGES_SNAPSHOT","messages":[]}\n'
            '\n',
          );
        });

        final transport = AgUiHttpTransport(
          httpClient: client,
          config: AgUiTransportConfig(
            baseUrl: Uri.parse('https://stack.example.com'),
            authHeaderProvider: () async => const {
              'Authorization': 'Bearer test-id-token',
            },
          ),
        );

        final events = await transport
            .connect(input: const ConnectAgentInput(threadId: 'thread-123'))
            .toList();

        expect(events, hasLength(1));
        expect(events.single.type, 'MESSAGES_SNAPSHOT');
      },
    );

    test('advertises resume support and posts resume decisions', () async {
      final client = _RecordingStreamingClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://stack.example.com/api/client/copilotkit/agent/maistack_agent/resume',
        );
        expect(request.headers['authorization'], 'Bearer test-id-token');
        expect(request.headers['content-type'], 'application/json');

        final body =
            jsonDecode((request as http.Request).body) as Map<String, Object?>;
        expect(body['threadId'], 'thread-123');
        expect(body['thread_id'], 'thread-123');
        expect(body['interruptedRunId'], 'run-123');
        expect(body['interrupted_run_id'], 'run-123');
        expect(body['decision'], 'approve');

        return http.StreamedResponse(
          Stream<List<int>>.fromIterable([
            utf8.encode('{"threadId":"thread-123","runId":"run-456"}'),
          ]),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });

      final transport = AgUiHttpTransport(
        httpClient: client,
        config: AgUiTransportConfig(
          baseUrl: Uri.parse('https://stack.example.com'),
          supportsResume: true,
          authHeaderProvider: () async => const {
            'Authorization': 'Bearer test-id-token',
          },
        ),
      );

      final capabilities = await transport.getCapabilities(
        agentId: 'assistant',
      );
      expect(capabilities.supportsCapabilityDiscovery, isFalse);
      expect(capabilities.supportsAbort, isFalse);
      expect(capabilities.supportsResume, isTrue);

      final result = await transport.resume(
        const AgUiResumeRequest(
          threadId: 'thread-123',
          interruptedRunId: 'run-123',
          payload: <String, Object?>{'decision': 'approve'},
        ),
      );
      expect(result.threadId, 'thread-123');
      expect(result.runId, 'run-456');
    });
  });
}

class _RecordingStreamingClient extends http.BaseClient {
  _RecordingStreamingClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

http.StreamedResponse _sseResponse(String body, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream<List<int>>.fromIterable([utf8.encode(body)]),
    statusCode,
    headers: const {'content-type': 'text/event-stream'},
  );
}
