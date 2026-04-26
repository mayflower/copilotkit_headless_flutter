import 'package:flutter/foundation.dart';

import '../agui/reducer/json_patch_service.dart';
import '../agui/session/shared_state_document.dart';

typedef CopilotCoAgentStateDecoder<T> = T Function(Map<String, Object?> data);
typedef CopilotCoAgentStateEncoder<T> = Map<String, Object?> Function(T value);

class CopilotCoAgentScope {
  const CopilotCoAgentScope({required this.agentId, this.nodeId});

  final String agentId;
  final String? nodeId;
}

class CopilotCoAgentStateController<T> extends ChangeNotifier {
  CopilotCoAgentStateController({
    required CopilotCoAgentScope scope,
    required SharedStateDocument document,
    required CopilotCoAgentStateDecoder<T> decoder,
    required CopilotCoAgentStateEncoder<T> encoder,
    JsonPatchService patchService = const JsonPatchService(),
  }) : _scope = scope,
       _document = document,
       _decoder = decoder,
       _encoder = encoder,
       _patchService = patchService;

  final CopilotCoAgentScope _scope;
  final CopilotCoAgentStateDecoder<T> _decoder;
  final CopilotCoAgentStateEncoder<T> _encoder;
  final JsonPatchService _patchService;
  SharedStateDocument _document;

  CopilotCoAgentScope get scope => _scope;

  SharedStateDocument get document => _document;

  Map<String, Object?> get rawValue => _scopedData(_document.data, _scope);

  T get value => _decoder(rawValue);

  void bindDocument(SharedStateDocument document) {
    _document = document;
    notifyListeners();
  }

  SharedStateDocument setValue(T value) {
    final nextData = _writeScopedData(_document.data, _scope, _encoder(value));
    _document = _document.copyWith(data: nextData);
    notifyListeners();
    return _document;
  }

  SharedStateDocument patch(List<Object?> patch) {
    final scopedDocument = SharedStateDocument(data: rawValue);
    final patched = _patchService.apply(scopedDocument, patch);
    _document = _document.copyWith(
      data: _writeScopedData(_document.data, _scope, patched.data),
    );
    notifyListeners();
    return _document;
  }
}

Map<String, Object?> _scopedData(
  Map<String, Object?> root,
  CopilotCoAgentScope scope,
) {
  final agentData = _objectMap(root[scope.agentId]);
  final nodeId = scope.nodeId;
  if (nodeId == null) {
    return agentData;
  }
  return _objectMap(agentData[nodeId]);
}

Map<String, Object?> _writeScopedData(
  Map<String, Object?> root,
  CopilotCoAgentScope scope,
  Map<String, Object?> value,
) {
  final nextRoot = Map<String, Object?>.from(root);
  final nodeId = scope.nodeId;
  if (nodeId == null) {
    nextRoot[scope.agentId] = Map<String, Object?>.unmodifiable(value);
    return Map<String, Object?>.unmodifiable(nextRoot);
  }

  final agentData = Map<String, Object?>.from(_objectMap(root[scope.agentId]));
  agentData[nodeId] = Map<String, Object?>.unmodifiable(value);
  nextRoot[scope.agentId] = Map<String, Object?>.unmodifiable(agentData);
  return Map<String, Object?>.unmodifiable(nextRoot);
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.from(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), nestedValue),
    );
  }
  return const <String, Object?>{};
}
