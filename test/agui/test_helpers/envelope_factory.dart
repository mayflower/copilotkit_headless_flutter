import 'dart:convert';

import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_event_envelope.dart';

AgUiEventEnvelope envelopeFromJson(
  Map<String, Object?> json, {
  DateTime? receivedAt,
}) {
  return AgUiEventEnvelope.fromRawPayload(
    rawPayload: jsonEncode(json),
    receivedAt: receivedAt ?? DateTime.utc(2026, 1, 1),
  );
}

AgUiEventEnvelope malformedEnvelope({
  required String rawPayload,
  DateTime? receivedAt,
  String? sseEventName,
}) {
  return AgUiEventEnvelope.fromRawPayload(
    rawPayload: rawPayload,
    receivedAt: receivedAt ?? DateTime.utc(2026, 1, 1),
    sseEventName: sseEventName,
  );
}
