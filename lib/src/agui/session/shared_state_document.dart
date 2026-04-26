import '../protocol/agui_json.dart';

class SharedStateDocument {
  const SharedStateDocument({
    required this.data,
    this.lastSnapshotAt,
    this.lastDeltaAt,
  });

  factory SharedStateDocument.empty() {
    return const SharedStateDocument(data: <String, Object?>{});
  }

  factory SharedStateDocument.fromJson(
    Map<String, Object?> json, {
    DateTime? capturedAt,
  }) {
    return SharedStateDocument(
      data: normalizeObjectMap(json),
      lastSnapshotAt: capturedAt,
    );
  }

  // Snapshot/delta timestamps stay on the document so later phases can add
  // version or dedupe metadata without collapsing back to a raw map.
  final Map<String, Object?> data;
  final DateTime? lastSnapshotAt;
  final DateTime? lastDeltaAt;

  SharedStateDocument copyWith({
    Map<String, Object?>? data,
    Object? lastSnapshotAt = _unset,
    Object? lastDeltaAt = _unset,
  }) {
    return SharedStateDocument(
      data: data ?? this.data,
      lastSnapshotAt: identical(lastSnapshotAt, _unset)
          ? this.lastSnapshotAt
          : lastSnapshotAt as DateTime?,
      lastDeltaAt: identical(lastDeltaAt, _unset)
          ? this.lastDeltaAt
          : lastDeltaAt as DateTime?,
    );
  }
}

const _unset = Object();
