import 'agui_json.dart';

enum AgUiMessageRole {
  user,
  assistant,
  system,
  tool,
  developer,
  activity,
  reasoning,
  unknown,
}

sealed class AgUiMessageContentPart {
  const AgUiMessageContentPart();

  Object toJson();
}

final class AgUiTextContentPart extends AgUiMessageContentPart {
  const AgUiTextContentPart({required this.text});

  final String text;

  @override
  Object toJson() => <String, Object?>{'type': 'text', 'text': text};
}

final class AgUiImageContentPart extends AgUiMessageContentPart {
  const AgUiImageContentPart({required this.url, this.mimeType});

  final String url;
  final String? mimeType;

  @override
  Object toJson() => <String, Object?>{
    'type': 'image',
    'url': url,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

final class AgUiFileContentPart extends AgUiMessageContentPart {
  const AgUiFileContentPart({
    required this.assetId,
    required this.name,
    this.mimeType,
  });

  final String assetId;
  final String name;
  final String? mimeType;

  @override
  Object toJson() => <String, Object?>{
    'type': 'file',
    'assetId': assetId,
    'name': name,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

class AgUiMessage {
  const AgUiMessage({
    required this.id,
    required this.role,
    required this.content,
    this.metadata = const <String, Object?>{},
  });

  factory AgUiMessage.fromJson(Map<String, Object?> json) {
    final normalized = normalizeObjectMap(json);
    return AgUiMessage(
      id: normalizeString(normalized['id']) ?? '',
      role: _roleFromJson(normalized['role']),
      content: _decodeContent(normalized['content']),
      metadata: _metadataFromJson(normalized),
    );
  }

  final String id;
  final AgUiMessageRole role;
  final List<AgUiMessageContentPart> content;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'role': _roleToJson(role),
    'content': _encodeContent(content),
    ...metadata,
  };

  static Object _encodeContent(List<AgUiMessageContentPart> content) {
    if (content.length == 1) {
      final first = content.first;
      if (first is AgUiTextContentPart) {
        return first.text;
      }
    }

    return content.map((part) => part.toJson()).toList(growable: false);
  }

  static List<AgUiMessageContentPart> _decodeContent(Object? value) {
    if (value is String) {
      return <AgUiMessageContentPart>[AgUiTextContentPart(text: value)];
    }
    if (value is Map) {
      return <AgUiMessageContentPart>[_decodeContentPart(value)];
    }
    if (value is List) {
      return value.map(_decodeContentPart).toList(growable: false);
    }
    return const <AgUiMessageContentPart>[];
  }

  static AgUiMessageContentPart _decodeContentPart(Object? value) {
    if (value is String) {
      return AgUiTextContentPart(text: value);
    }

    final object = normalizeObjectMap(value);
    final type = normalizeString(object['type'])?.toLowerCase();
    return switch (type) {
      'image' => AgUiImageContentPart(
        url: normalizeString(object['url']) ?? '',
        mimeType: normalizeString(object['mimeType']),
      ),
      'file' => AgUiFileContentPart(
        assetId: normalizeString(object['assetId']) ?? '',
        name: normalizeString(object['name']) ?? '',
        mimeType: normalizeString(object['mimeType']),
      ),
      _ => AgUiTextContentPart(
        text:
            normalizeString(object['text']) ??
            normalizeString(object['content']) ??
            normalizeString(object['value']) ??
            '',
      ),
    };
  }

  static Map<String, Object?> _metadataFromJson(Map<String, Object?> json) {
    return Map<String, Object?>.from(json)
      ..remove('id')
      ..remove('role')
      ..remove('content');
  }
}

AgUiMessageRole _roleFromJson(Object? value) {
  return switch (normalizeString(value)?.toLowerCase()) {
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

String _roleToJson(AgUiMessageRole role) {
  return switch (role) {
    AgUiMessageRole.user => 'user',
    AgUiMessageRole.assistant => 'assistant',
    AgUiMessageRole.system => 'system',
    AgUiMessageRole.tool => 'tool',
    AgUiMessageRole.developer => 'developer',
    AgUiMessageRole.activity => 'activity',
    AgUiMessageRole.reasoning => 'reasoning',
    AgUiMessageRole.unknown => 'unknown',
  };
}
