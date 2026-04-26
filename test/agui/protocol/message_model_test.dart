import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_message.dart';

import 'agui_fixture_loader.dart';

void main() {
  group('AgUiMessage', () {
    test('decodes supported roles from fixtures', () async {
      final userMessage = AgUiMessage.fromJson(
        await loadAgUiFixture('message_user_text.json'),
      );
      final developerMessage = AgUiMessage.fromJson(
        await loadAgUiFixture('message_developer_multimodal.json'),
      );
      final reasoningMessage = AgUiMessage.fromJson(
        await loadAgUiFixture('message_reasoning_text.json'),
      );

      expect(userMessage.role, AgUiMessageRole.user);
      expect(developerMessage.role, AgUiMessageRole.developer);
      expect(reasoningMessage.role, AgUiMessageRole.reasoning);
    });

    test('decodes text, image, and file content variants', () async {
      final message = AgUiMessage.fromJson(
        await loadAgUiFixture('message_developer_multimodal.json'),
      );

      expect(message.id, 'msg_multimodal');
      expect(message.content, hasLength(3));
      expect(message.content[0], isA<AgUiTextContentPart>());
      expect(message.content[1], isA<AgUiImageContentPart>());
      expect(message.content[2], isA<AgUiFileContentPart>());

      final textPart = message.content[0] as AgUiTextContentPart;
      final imagePart = message.content[1] as AgUiImageContentPart;
      final filePart = message.content[2] as AgUiFileContentPart;

      expect(textPart.text, 'Please compare the attached artifacts.');
      expect(imagePart.url, 'https://cdn.example.com/images/diff.png');
      expect(imagePart.mimeType, 'image/png');
      expect(filePart.assetId, 'asset_pdf_7');
      expect(filePart.name, 'spec.pdf');
      expect(filePart.mimeType, 'application/pdf');
    });

    test(
      'round-trips normalized message JSON without flattening multimodal content',
      () async {
        final message = AgUiMessage.fromJson(
          await loadAgUiFixture('message_developer_multimodal.json'),
        );

        expect(message.toJson(), <String, Object?>{
          'id': 'msg_multimodal',
          'role': 'developer',
          'content': <Object?>[
            <String, Object?>{
              'type': 'text',
              'text': 'Please compare the attached artifacts.',
            },
            <String, Object?>{
              'type': 'image',
              'url': 'https://cdn.example.com/images/diff.png',
              'mimeType': 'image/png',
            },
            <String, Object?>{
              'type': 'file',
              'assetId': 'asset_pdf_7',
              'name': 'spec.pdf',
              'mimeType': 'application/pdf',
            },
          ],
        });
      },
    );
  });
}
