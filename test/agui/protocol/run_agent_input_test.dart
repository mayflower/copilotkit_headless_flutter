import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/agui_message.dart';
import 'package:copilotkit_headless_flutter/src/agui/protocol/run_agent_input.dart';

void main() {
  group('RunAgentInput', () {
    test('request builder emits expected AG-UI JSON fields', () {
      final input = RunAgentInput(
        threadId: 'thread_9f8c',
        runId: 'run_b5d1',
        parentRunId: 'run_parent',
        messages: <AgUiMessage>[
          const AgUiMessage(
            id: 'm1',
            role: AgUiMessageRole.user,
            content: <AgUiMessageContentPart>[
              AgUiTextContentPart(text: 'Bitte pruefe die Freigabe.'),
              AgUiFileContentPart(
                assetId: 'asset_42',
                name: 'invoice.pdf',
                mimeType: 'application/pdf',
              ),
            ],
          ),
        ],
        state: const <String, Object?>{
          'selectedDraftId': 'draft_42',
          'uiMode': 'mobile',
        },
        tools: const <AgUiToolDefinition>[
          AgUiToolDefinition(
            name: 'pick_file',
            description: 'Waehlt eine Datei aus',
          ),
        ],
        context: const <AgUiContextEntry>[
          AgUiContextEntry(key: 'locale', value: 'de-DE'),
          AgUiContextEntry(key: 'platform', value: 'android'),
        ],
        forwardedProps: const <String, Object?>{
          'appVersion': '1.0.0',
          'buildFlavor': 'prod',
        },
      );

      expect(input.toJson(), <String, Object?>{
        'threadId': 'thread_9f8c',
        'runId': 'run_b5d1',
        'parentRunId': 'run_parent',
        'messages': <Object?>[
          <String, Object?>{
            'id': 'm1',
            'role': 'user',
            'content': <Object?>[
              <String, Object?>{
                'type': 'text',
                'text': 'Bitte pruefe die Freigabe.',
              },
              <String, Object?>{
                'type': 'file',
                'assetId': 'asset_42',
                'name': 'invoice.pdf',
                'mimeType': 'application/pdf',
              },
            ],
          },
        ],
        'state': <String, Object?>{
          'selectedDraftId': 'draft_42',
          'uiMode': 'mobile',
        },
        'tools': <Object?>[
          <String, Object?>{
            'name': 'pick_file',
            'description': 'Waehlt eine Datei aus',
          },
        ],
        'context': <Object?>[
          <String, Object?>{'key': 'locale', 'value': 'de-DE'},
          <String, Object?>{'key': 'platform', 'value': 'android'},
        ],
        'forwardedProps': <String, Object?>{
          'appVersion': '1.0.0',
          'buildFlavor': 'prod',
        },
      });
    });

    test('userTextTurn builds a minimal single-user-message request', () {
      final input = RunAgentInput.userTextTurn(
        threadId: 'thread_simple',
        runId: 'run_simple',
        messageId: 'm_simple',
        text: 'Hello mobile edge.',
      );

      expect(input.toJson(), <String, Object?>{
        'threadId': 'thread_simple',
        'runId': 'run_simple',
        'messages': <Object?>[
          <String, Object?>{
            'id': 'm_simple',
            'role': 'user',
            'content': 'Hello mobile edge.',
          },
        ],
        'state': <String, Object?>{},
        'tools': <Object?>[],
        'context': <Object?>[],
        'forwardedProps': <String, Object?>{},
      });
    });
  });
}
