import '../protocol/agui_event_envelope.dart';
import '../protocol/agui_message.dart';
import '../session/thread_session.dart';
import 'agui_reducer.dart';

class MessageReducer implements AgUiReducer {
  const MessageReducer();

  @override
  ThreadSession reduce(ThreadSession current, AgUiEventEnvelope event) {
    switch (event.type) {
      case 'MESSAGES_SNAPSHOT':
        return current.copyWith(
          messages: _messagesFromSnapshot(event.listValue('messages')),
        );
      case 'TEXT_MESSAGE_START':
      case 'TEXT_MESSAGE_CHUNK' when event.stringValue('delta') == null:
        return current.copyWith(
          messages: _upsertMessage(
            current.messages,
            UiMessage(
              id:
                  event.stringValue('messageId') ??
                  event.stringValue('message_id') ??
                  'message-${current.messages.length + 1}',
              role: _roleFromWire(event.stringValue('role')),
              text: '',
              isStreaming: true,
            ),
          ),
        );
      case 'TEXT_MESSAGE_CONTENT':
      case 'TEXT_MESSAGE_CHUNK':
        final messageId =
            event.stringValue('messageId') ??
            event.stringValue('message_id') ??
            'message-${current.messages.length + 1}';
        final delta =
            _readRawString(event.payload['delta']) ??
            _readRawString(event.payload['content']) ??
            '';
        if (delta.isEmpty) {
          return current;
        }

        final existingIndex = current.messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (existingIndex < 0) {
          return current.copyWith(
            messages: [
              ...current.messages,
              UiMessage(
                id: messageId,
                role: _roleFromWire(event.stringValue('role')),
                text: delta,
                isStreaming: true,
              ),
            ],
          );
        }

        final existing = current.messages[existingIndex];
        final updated = existing.copyWith(
          text: '${existing.text}$delta',
          isStreaming: true,
        );
        return current.copyWith(
          messages: [
            ...current.messages.take(existingIndex),
            updated,
            ...current.messages.skip(existingIndex + 1),
          ],
        );
      case 'TEXT_MESSAGE_END':
        final messageId =
            event.stringValue('messageId') ?? event.stringValue('message_id');
        if (messageId == null) {
          return current;
        }
        final existingIndex = current.messages.indexWhere(
          (message) => message.id == messageId,
        );
        if (existingIndex < 0) {
          return current;
        }
        final updated = current.messages[existingIndex].copyWith(
          isStreaming: false,
        );
        return current.copyWith(
          messages: [
            ...current.messages.take(existingIndex),
            updated,
            ...current.messages.skip(existingIndex + 1),
          ],
        );
      default:
        return current;
    }
  }
}

List<UiMessage> _messagesFromSnapshot(List<Object?>? items) {
  if (items == null) {
    return const <UiMessage>[];
  }

  final messages = <UiMessage>[];
  for (final item in items) {
    if (item is! Map) {
      continue;
    }
    final agUiMessage = AgUiMessage.fromJson(
      item.map((key, value) => MapEntry(key.toString(), value)),
    );
    messages.add(
      UiMessage(
        id: agUiMessage.id,
        role: agUiMessage.role,
        text: _flattenMessageContent(agUiMessage.content),
      ),
    );
  }
  return messages;
}

String _flattenMessageContent(List<AgUiMessageContentPart> parts) {
  final buffer = <String>[];
  for (final part in parts) {
    switch (part) {
      case AgUiTextContentPart(:final text):
        if (text.trim().isNotEmpty) {
          buffer.add(text);
        }
      case AgUiFileContentPart(:final name):
        if (name.trim().isNotEmpty) {
          buffer.add(name);
        }
      case AgUiImageContentPart(:final url):
        if (url.trim().isNotEmpty) {
          buffer.add(url);
        }
    }
  }
  return buffer.join('\n');
}

List<UiMessage> _upsertMessage(List<UiMessage> messages, UiMessage candidate) {
  final existingIndex = messages.indexWhere(
    (message) => message.id == candidate.id,
  );
  if (existingIndex < 0) {
    return [...messages, candidate];
  }
  return [
    ...messages.take(existingIndex),
    candidate,
    ...messages.skip(existingIndex + 1),
  ];
}

AgUiMessageRole _roleFromWire(String? role) {
  return switch (role?.trim().toLowerCase()) {
    'user' => AgUiMessageRole.user,
    'assistant' => AgUiMessageRole.assistant,
    'system' => AgUiMessageRole.system,
    'tool' => AgUiMessageRole.tool,
    'developer' => AgUiMessageRole.developer,
    'activity' => AgUiMessageRole.activity,
    'reasoning' => AgUiMessageRole.reasoning,
    _ => AgUiMessageRole.unknown,
  };
}

String? _readRawString(Object? value) {
  if (value is! String) {
    return null;
  }
  return value.isEmpty ? null : value;
}
