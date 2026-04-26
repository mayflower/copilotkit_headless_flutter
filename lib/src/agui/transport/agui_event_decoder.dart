import '../protocol/agui_event_envelope.dart';
import 'sse_frame_parser.dart';

Stream<AgUiEventEnvelope> decodeAgUiEventStream(
  Stream<List<int>> byteStream,
) async* {
  final parser = const SseFrameParser();
  await for (final frame in parser.parse(byteStream)) {
    yield AgUiEventEnvelope.fromRawPayload(
      rawPayload: frame.data,
      receivedAt: DateTime.now().toUtc(),
      sseEventName: frame.event,
      sseEventId: frame.id,
    );
  }
}

Stream<SseFrame> decodeSseFrames(Stream<List<int>> byteStream) {
  return const SseFrameParser().parse(byteStream);
}
