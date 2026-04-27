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

enum AgUiInputSourceType { data, url }

class AgUiInputContentSource {
  const AgUiInputContentSource({
    required this.type,
    required this.value,
    this.mimeType,
  });

  const AgUiInputContentSource.data({
    required String value,
    required String mimeType,
  }) : this(type: AgUiInputSourceType.data, value: value, mimeType: mimeType);

  const AgUiInputContentSource.url({required String value, String? mimeType})
    : this(type: AgUiInputSourceType.url, value: value, mimeType: mimeType);

  final AgUiInputSourceType type;
  final String value;
  final String? mimeType;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': switch (type) {
      AgUiInputSourceType.data => 'data',
      AgUiInputSourceType.url => 'url',
    },
    'value': value,
    if (mimeType != null) 'mimeType': mimeType,
  };

  static AgUiInputContentSource fromJson(Object? value) {
    final object = normalizeObjectMap(value);
    final type = normalizeString(object['type'])?.toLowerCase();
    return AgUiInputContentSource(
      type: type == 'data' ? AgUiInputSourceType.data : AgUiInputSourceType.url,
      value: normalizeString(object['value']) ?? '',
      mimeType: normalizeString(object['mimeType']),
    );
  }
}

abstract base class AgUiSourcedContentPart extends AgUiMessageContentPart {
  const AgUiSourcedContentPart({required this.source, this.metadata});

  final AgUiInputContentSource source;
  final Object? metadata;

  String get wireType;

  String get url => source.value;
  String? get mimeType => source.mimeType;

  @override
  Object toJson() => <String, Object?>{
    'type': wireType,
    'source': source.toJson(),
    if (metadata != null) 'metadata': metadata,
  };
}

final class AgUiImageContentPart extends AgUiSourcedContentPart {
  const AgUiImageContentPart({required super.source, super.metadata});

  AgUiImageContentPart.url({
    required String url,
    String? mimeType,
    Object? metadata,
  }) : this(
         source: AgUiInputContentSource.url(value: url, mimeType: mimeType),
         metadata: metadata,
       );

  AgUiImageContentPart.data({
    required String data,
    required String mimeType,
    Object? metadata,
  }) : this(
         source: AgUiInputContentSource.data(value: data, mimeType: mimeType),
         metadata: metadata,
       );

  @override
  String get wireType => 'image';
}

final class AgUiAudioContentPart extends AgUiSourcedContentPart {
  const AgUiAudioContentPart({required super.source, super.metadata});

  @override
  String get wireType => 'audio';
}

final class AgUiVideoContentPart extends AgUiSourcedContentPart {
  const AgUiVideoContentPart({required super.source, super.metadata});

  @override
  String get wireType => 'video';
}

final class AgUiDocumentContentPart extends AgUiSourcedContentPart {
  const AgUiDocumentContentPart({required super.source, super.metadata});

  @override
  String get wireType => 'document';
}

final class AgUiBinaryContentPart extends AgUiMessageContentPart {
  const AgUiBinaryContentPart({
    required this.mimeType,
    this.id,
    this.url,
    this.data,
    this.filename,
  });

  final String mimeType;
  final String? id;
  final String? url;
  final String? data;
  final String? filename;

  @override
  Object toJson() => <String, Object?>{
    'type': 'binary',
    'mimeType': mimeType,
    if (id != null) 'id': id,
    if (url != null) 'url': url,
    if (data != null) 'data': data,
    if (filename != null) 'filename': filename,
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
        source: AgUiInputContentSource.fromJson(object['source']),
        metadata: object['metadata'],
      ),
      'audio' => AgUiAudioContentPart(
        source: AgUiInputContentSource.fromJson(object['source']),
        metadata: object['metadata'],
      ),
      'video' => AgUiVideoContentPart(
        source: AgUiInputContentSource.fromJson(object['source']),
        metadata: object['metadata'],
      ),
      'document' => AgUiDocumentContentPart(
        source: AgUiInputContentSource.fromJson(object['source']),
        metadata: object['metadata'],
      ),
      'binary' => AgUiBinaryContentPart(
        mimeType: normalizeString(object['mimeType']) ?? '',
        id: normalizeString(object['id']),
        url: normalizeString(object['url']),
        data: normalizeString(object['data']),
        filename: normalizeString(object['filename']),
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
