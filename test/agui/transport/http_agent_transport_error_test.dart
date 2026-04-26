import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:copilotkit_headless_flutter/src/agui/protocol/run_agent_input.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agui_http_transport.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agui_transport_config.dart';

void main() {
  group('AgUiHttpTransport errors', () {
    test('surfaces malformed JSON without crashing the stream', () async {
      final client = _StreamingClient((request) async {
        return _sseResponse(
          'event: RUN_STARTED\n'
          'data: {"runId":"run-123"\n'
          '\n'
          'event: RUN_FINISHED\n'
          'data: {"runId":"run-123"}\n'
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

      final envelopes = await transport
          .run(
            RunAgentInput.userTextTurn(
              threadId: 'thread-123',
              runId: 'run-123',
              messageId: 'message-1',
              text: 'Hello',
            ),
          )
          .toList();

      expect(envelopes, hasLength(2));
      expect(envelopes.first.event, isNull);
      expect(envelopes.first.decodeErrorMessage, isNotNull);
      expect(envelopes.first.rawPayload, '{"runId":"run-123"');
      expect(envelopes.last.type, 'RUN_FINISHED');
    });

    test('surfaces HTTP failures with status code context', () async {
      final client = _StreamingClient((request) async {
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable([
            utf8.encode('{"error":"Unauthorized"}'),
          ]),
          401,
          headers: const {'content-type': 'application/json'},
        );
      });

      final transport = AgUiHttpTransport(
        httpClient: client,
        config: AgUiTransportConfig(
          baseUrl: Uri.parse('https://stack.example.com'),
          authHeaderProvider: () async => const {
            'Authorization': 'Bearer bad-token',
          },
        ),
      );

      expect(
        () => transport
            .run(
              RunAgentInput.userTextTurn(
                threadId: 'thread-123',
                runId: 'run-123',
                messageId: 'message-1',
                text: 'Hello',
              ),
            )
            .toList(),
        throwsA(
          isA<AgUiTransportException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                contains('Unauthorized'),
              ),
        ),
      );
    });

    test('surfaces connection timeouts with transport context', () async {
      final client = _StreamingClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return _sseResponse(
          'event: RUN_STARTED\n'
          'data: {"type":"RUN_STARTED","runId":"run-123"}\n'
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
          connectionTimeout: const Duration(milliseconds: 5),
        ),
      );

      expect(
        () => transport
            .run(
              RunAgentInput.userTextTurn(
                threadId: 'thread-123',
                runId: 'run-123',
                messageId: 'message-1',
                text: 'Hello',
              ),
            )
            .toList(),
        throwsA(
          isA<AgUiTransportException>().having(
            (error) => error.message,
            'message',
            contains('connection timed out'),
          ),
        ),
      );
    });

    test('surfaces stream read timeouts with transport context', () async {
      final client = _StreamingClient((request) async {
        return http.StreamedResponse(
          Stream<List<int>>.fromFuture(
            Future<List<int>>.delayed(
              const Duration(milliseconds: 30),
              () => utf8.encode(
                'event: RUN_STARTED\n'
                'data: {"type":"RUN_STARTED","runId":"run-123"}\n'
                '\n',
              ),
            ),
          ),
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
          readTimeout: const Duration(milliseconds: 5),
        ),
      );

      expect(
        () => transport
            .run(
              RunAgentInput.userTextTurn(
                threadId: 'thread-123',
                runId: 'run-123',
                messageId: 'message-1',
                text: 'Hello',
              ),
            )
            .toList(),
        throwsA(
          isA<AgUiTransportException>().having(
            (error) => error.message,
            'message',
            contains('stream read timed out'),
          ),
        ),
      );
    });
  });
}

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this._handler);

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
