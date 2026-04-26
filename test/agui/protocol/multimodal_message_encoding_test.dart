import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_message.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/run_agent_input.dart';

void main() {
  group('RunAgentInput.userMultimodalTurn', () {
    test('encodes structured content parts without flattening attachments', () {
      final input = RunAgentInput.userMultimodalTurn(
        threadId: 'thread_multimodal',
        runId: 'run_multimodal',
        messageId: 'message_multimodal',
        content: const <AgUiMessageContentPart>[
          AgUiTextContentPart(text: 'Please compare these artifacts.'),
          AgUiImageContentPart(
            url: 'https://uploads.example.com/assets/diff.png',
            mimeType: 'image/png',
          ),
          AgUiFileContentPart(
            assetId: 'asset_pdf_7',
            name: 'spec.pdf',
            mimeType: 'application/pdf',
          ),
        ],
      );

      expect(input.toJson(), <String, Object?>{
        'threadId': 'thread_multimodal',
        'runId': 'run_multimodal',
        'messages': <Object?>[
          <String, Object?>{
            'id': 'message_multimodal',
            'role': 'user',
            'content': <Object?>[
              <String, Object?>{
                'type': 'text',
                'text': 'Please compare these artifacts.',
              },
              <String, Object?>{
                'type': 'image',
                'url': 'https://uploads.example.com/assets/diff.png',
                'mimeType': 'image/png',
              },
              <String, Object?>{
                'type': 'file',
                'assetId': 'asset_pdf_7',
                'name': 'spec.pdf',
                'mimeType': 'application/pdf',
              },
            ],
          },
        ],
        'state': <String, Object?>{},
        'tools': <Object?>[],
        'context': <Object?>[],
        'forwardedProps': <String, Object?>{},
      });
    });

    test('supports URL-only content without inventing empty text parts', () {
      final input = RunAgentInput.userMultimodalTurn(
        threadId: 'thread_url_only',
        runId: 'run_url_only',
        messageId: 'message_url_only',
        content: const <AgUiMessageContentPart>[
          AgUiImageContentPart(
            url: 'https://uploads.example.com/assets/receipt.png',
            mimeType: 'image/png',
          ),
        ],
      );

      expect(
        ((input.toJson()['messages'] as List<Object?>).single
            as Map<String, Object?>)['content'],
        <Object?>[
          <String, Object?>{
            'type': 'image',
            'url': 'https://uploads.example.com/assets/receipt.png',
            'mimeType': 'image/png',
          },
        ],
      );
    });
  });
}
