import 'dart:async';
import 'dart:convert';

class SseFrame {
  const SseFrame({required this.data, this.event, this.id});

  final String data;
  final String? event;
  final String? id;
}

class SseFrameParser {
  const SseFrameParser();

  Stream<SseFrame> parse(Stream<List<int>> byteStream) async* {
    final lines = const LineSplitter().bind(utf8.decoder.bind(byteStream));

    String? event;
    String? id;
    final dataLines = <String>[];

    SseFrame? flush() {
      if (event == null && id == null && dataLines.isEmpty) {
        return null;
      }

      final frame = SseFrame(event: event, id: id, data: dataLines.join('\n'));
      event = null;
      id = null;
      dataLines.clear();
      return frame;
    }

    await for (final rawLine in lines) {
      final line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      if (line.isEmpty) {
        final frame = flush();
        if (frame != null) {
          yield frame;
        }
        continue;
      }

      if (line.startsWith(':')) {
        continue;
      }

      final separatorIndex = line.indexOf(':');
      final field = separatorIndex >= 0
          ? line.substring(0, separatorIndex)
          : line;
      var value = separatorIndex >= 0 ? line.substring(separatorIndex + 1) : '';
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }

      if (field == 'event') {
        event = value;
      } else if (field == 'data') {
        dataLines.add(value);
      } else if (field == 'id') {
        id = value;
      }
    }

    final trailingFrame = flush();
    if (trailingFrame != null) {
      yield trailingFrame;
    }
  }
}
