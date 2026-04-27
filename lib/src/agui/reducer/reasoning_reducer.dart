import '../protocol/agui_event_envelope.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';

class ReasoningReducer implements AgUiReducer {
  const ReasoningReducer();

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    final messageId =
        event.stringValue('messageId') ?? event.stringValue('entityId');
    if (messageId == null && event.type != 'REASONING_ENCRYPTED_VALUE') {
      return current;
    }

    final nextReasoning = switch (event.type) {
      'REASONING_START' => ReasoningViewModel(id: messageId!),
      'REASONING_MESSAGE_START' =>
        (current.reasoning[messageId] ?? ReasoningViewModel(id: messageId!))
            .copyWith(stage: ReasoningStage.streaming),
      'REASONING_MESSAGE_CONTENT' || 'REASONING_MESSAGE_CHUNK' =>
        _appendReasoningDelta(current.reasoning[messageId], messageId!, event),
      'REASONING_MESSAGE_END' || 'REASONING_END' =>
        (current.reasoning[messageId] ?? ReasoningViewModel(id: messageId!))
            .copyWith(stage: ReasoningStage.ended),
      'REASONING_ENCRYPTED_VALUE' => _storeEncryptedValue(current, event),
      _ => null,
    };

    if (nextReasoning == null) {
      return current;
    }

    return current.copyWith(
      reasoning: <String, ReasoningViewModel>{
        ...current.reasoning,
        nextReasoning.id: nextReasoning,
      },
    );
  }
}

ReasoningViewModel _appendReasoningDelta(
  ReasoningViewModel? existing,
  String messageId,
  AgUiEventEnvelope event,
) {
  final delta =
      _readRawString(event.payload['delta']) ??
      _readRawString(event.payload['content']) ??
      '';
  final base = existing ?? ReasoningViewModel(id: messageId);
  return base.copyWith(
    stage: ReasoningStage.streaming,
    text: '${base.text}$delta',
  );
}

String? _readRawString(Object? value) {
  if (value is! String) {
    return null;
  }
  return value.isEmpty ? null : value;
}

ReasoningViewModel? _storeEncryptedValue(
  ThreadSession current,
  AgUiEventEnvelope event,
) {
  final encryptedValue =
      event.stringValue('encryptedValue') ??
      event.stringValue('encryptedContent');
  if (encryptedValue == null) {
    return null;
  }

  final entityId =
      event.stringValue('entityId') ??
      event.stringValue('messageId') ??
      'reasoning-encrypted';
  final subtype = event.stringValue('subtype') ?? 'value';
  final base = current.reasoning[entityId] ?? ReasoningViewModel(id: entityId);
  return base.copyWith(
    encryptedValues: <String, String>{
      ...base.encryptedValues,
      subtype: encryptedValue,
    },
  );
}
