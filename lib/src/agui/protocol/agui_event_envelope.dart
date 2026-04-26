import 'dart:convert';

import 'agui_event.dart';
import 'agui_json.dart';

class AgUiEventEnvelope {
  const AgUiEventEnvelope({
    required this.rawPayload,
    required this.receivedAt,
    this.sseEventName,
    this.sseEventId,
    this.event,
    this.decodeErrorMessage,
  });

  factory AgUiEventEnvelope.fromRawPayload({
    required String rawPayload,
    required DateTime receivedAt,
    String? sseEventName,
    String? sseEventId,
  }) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map) {
        return AgUiEventEnvelope(
          rawPayload: rawPayload,
          receivedAt: receivedAt,
          sseEventName: sseEventName,
          sseEventId: sseEventId,
          decodeErrorMessage: 'AG-UI payload must decode to a JSON object.',
        );
      }

      final payload = _mergeSseMetadata(
        normalizeObjectMap(decoded),
        sseEventName: sseEventName,
        sseEventId: sseEventId,
      );
      return AgUiEventEnvelope(
        rawPayload: rawPayload,
        receivedAt: receivedAt,
        sseEventName: sseEventName,
        sseEventId: sseEventId,
        event: AgUiEvent.fromJson(payload),
      );
    } on FormatException catch (error) {
      return AgUiEventEnvelope(
        rawPayload: rawPayload,
        receivedAt: receivedAt,
        sseEventName: sseEventName,
        sseEventId: sseEventId,
        decodeErrorMessage: error.message,
      );
    }
  }

  final String rawPayload;
  final DateTime receivedAt;
  final String? sseEventName;
  final String? sseEventId;
  final AgUiEvent? event;
  final String? decodeErrorMessage;

  String? get type => event?.type ?? sseEventName;

  Map<String, Object?> get payload =>
      event?.rawJson ?? const <String, Object?>{};

  String? stringValue(String key) => normalizeString(payload[key]);

  Map<String, Object?>? objectValue(String key) {
    final value = payload[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return normalizeObjectMap(value);
    }
    return null;
  }

  List<Object?>? listValue(String key) {
    final value = payload[key];
    if (value is List<Object?>) {
      return value;
    }
    if (value is List) {
      return normalizeObjectList(value);
    }
    return null;
  }
}

Map<String, Object?> _mergeSseMetadata(
  Map<String, Object?> payload, {
  String? sseEventName,
  String? sseEventId,
}) {
  return <String, Object?>{
    ...payload,
    if (!payload.containsKey('type') && sseEventName != null)
      'type': sseEventName,
    if (!payload.containsKey('eventId') && sseEventId != null)
      'eventId': sseEventId,
  };
}
