import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../protocol/agui_event_envelope.dart';
import '../protocol/connect_agent_input.dart';
import '../protocol/run_agent_input.dart';
import 'agent_transport.dart';
import 'agui_transport_config.dart';
import 'sse_frame_parser.dart';

class AgUiTransportException implements Exception {
  const AgUiTransportException({
    required this.message,
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'HTTP $statusCode: $message';
  }
}

class AgUiHttpTransport implements AgentTransport {
  AgUiHttpTransport({
    required http.Client httpClient,
    required AgUiTransportConfig config,
    SseFrameParser parser = const SseFrameParser(),
    DateTime Function()? clock,
  }) : _httpClient = httpClient,
       _config = config,
       _parser = parser,
       _clock = clock ?? DateTime.now;

  final http.Client _httpClient;
  final AgUiTransportConfig _config;
  final SseFrameParser _parser;
  final DateTime Function() _clock;

  @override
  Stream<AgUiEventEnvelope> connect({
    required ConnectAgentInput input,
    AgUiTransportCancellationToken? cancelToken,
  }) {
    return _openEventStream(
      endpoint: _config.connectUri,
      payload: input.toJson(),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<AgUiEventEnvelope> run(
    RunAgentInput input, {
    AgUiTransportCancellationToken? cancelToken,
  }) {
    return _openEventStream(
      endpoint: _config.runUri,
      payload: input.toJson(),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<AgUiCapabilitySet> getCapabilities({String? agentId}) async {
    return AgUiCapabilitySet(
      supportsAbort: _config.supportsAbort,
      supportsResume: _config.supportsResume,
      supportsFrontendTools: _config.supportsFrontendTools,
      supportedFrontendTools: _config.supportedFrontendTools,
    );
  }

  @override
  Future<void> abort({required String threadId, required String runId}) async {
    await _postJsonControl(
      endpoint: _config.abortUri,
      payload: <String, Object?>{'threadId': threadId, 'runId': runId},
    );
  }

  @override
  Future<AgUiResumeResult> resume(AgUiResumeRequest request) async {
    final payload = <String, Object?>{
      'threadId': request.threadId,
      'interruptedRunId': request.interruptedRunId,
      ...request.payload,
    };
    final response = await _postJsonControl(
      endpoint: _config.resumeUri,
      payload: payload,
    );

    return AgUiResumeResult(
      threadId: _readString(response, 'threadId') ?? request.threadId,
      runId: _readString(response, 'runId') ?? request.interruptedRunId,
    );
  }

  Future<Map<String, Object?>> _postJsonControl({
    required Uri endpoint,
    required Map<String, Object?> payload,
  }) async {
    final headers = await _config.authHeaderProvider();
    final response = await _httpClient
        .post(
          endpoint,
          headers: <String, String>{
            ...headers,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(
          _config.controlTimeout,
          onTimeout: () {
            throw AgUiTransportException(
              message:
                  'AG-UI control request timed out after ${_describeDuration(_config.controlTimeout)}.',
            );
          },
        );

    final body = _decodeJsonBody(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AgUiTransportException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(body) ?? 'AG-UI control request failed.',
      );
    }
    return _coerceObject(body) ?? const <String, Object?>{};
  }

  Stream<AgUiEventEnvelope> _openEventStream({
    required Uri endpoint,
    required Map<String, Object?> payload,
    AgUiTransportCancellationToken? cancelToken,
  }) async* {
    final request = http.Request('POST', endpoint)
      ..headers.addAll(await _config.authHeaderProvider())
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(payload);

    final response = await _httpClient
        .send(request)
        .timeout(
          _config.connectionTimeout,
          onTimeout: () {
            throw AgUiTransportException(
              message:
                  'AG-UI connection timed out after ${_describeDuration(_config.connectionTimeout)}.',
            );
          },
        );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AgUiTransportException(
        statusCode: response.statusCode,
        message: await _readErrorMessage(response),
      );
    }

    final envelopeStream = _parser
        .parse(response.stream)
        .timeout(
          _config.readTimeout,
          onTimeout: (sink) {
            sink.addError(
              AgUiTransportException(
                message:
                    'AG-UI stream read timed out after ${_describeDuration(_config.readTimeout)}.',
              ),
            );
            sink.close();
          },
        )
        .map(
          (frame) => AgUiEventEnvelope.fromRawPayload(
            rawPayload: frame.data,
            receivedAt: _clock().toUtc(),
            sseEventName: frame.event,
            sseEventId: frame.id,
          ),
        );

    late StreamSubscription<AgUiEventEnvelope> envelopeSubscription;
    StreamSubscription<void>? cancellationSubscription;
    StreamController<AgUiEventEnvelope>? controller;

    controller = StreamController<AgUiEventEnvelope>(
      onListen: () {
        envelopeSubscription = envelopeStream.listen(
          (envelope) {
            if (!(cancelToken?.isCancelled ?? false)) {
              controller?.add(envelope);
            }
          },
          onError: controller?.addError,
          onDone: () async {
            await cancellationSubscription?.cancel();
            await controller?.close();
          },
        );

        cancellationSubscription = cancelToken?.stream.listen((_) async {
          await envelopeSubscription.cancel();
          await controller?.close();
        });
      },
      onCancel: () async {
        await cancellationSubscription?.cancel();
        await envelopeSubscription.cancel();
      },
    );

    yield* controller.stream;
  }

  Future<String> _readErrorMessage(http.StreamedResponse response) async {
    final bodyBytes = await response.stream.toBytes();
    if (bodyBytes.isEmpty) {
      return 'AG-UI transport request failed.';
    }

    final bodyText = utf8.decode(bodyBytes);
    if (bodyText.trim().isEmpty) {
      return 'AG-UI transport request failed.';
    }

    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map) {
        for (final key in ['error', 'detail', 'message']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }
      }
    } on FormatException {
      return bodyText.trim();
    }

    return bodyText.trim();
  }

  Object? _decodeJsonBody(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) {
      return null;
    }
    final bodyText = utf8.decode(bodyBytes);
    if (bodyText.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(bodyText);
    } on FormatException {
      return bodyText.trim();
    }
  }

  Map<String, Object?>? _coerceObject(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }
    return null;
  }

  String? _extractErrorMessage(Object? payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }
    final object = _coerceObject(payload);
    if (object == null) {
      return null;
    }
    for (final key in ['error', 'detail', 'message']) {
      final value = object[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _readString(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _describeDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} s';
    }
    return '${duration.inMinutes} min';
  }
}
