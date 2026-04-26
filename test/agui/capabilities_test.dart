import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/capabilities/capability_service.dart';

void main() {
  group('CapabilityService', () {
    test('parsed capabilities drive feature gating', () {
      const service = CapabilityService();

      final snapshot = service.parse(<String, Object?>{
        'features': <String, Object?>{
          'frontend_tools': true,
          'resume': false,
          'reasoning': true,
          'multimodal_input': false,
        },
        'tools': <String, Object?>{
          'copy_to_clipboard': true,
          'open_map': false,
        },
      });

      expect(snapshot.frontendTools, CapabilityAvailability.available);
      expect(snapshot.resume, CapabilityAvailability.unavailable);
      expect(snapshot.reasoning, CapabilityAvailability.available);
      expect(snapshot.multimodalInput, CapabilityAvailability.unavailable);
      expect(
        snapshot.toolAvailability('copy_to_clipboard'),
        CapabilityAvailability.available,
      );
      expect(
        snapshot.toolAvailability('open_map'),
        CapabilityAvailability.unavailable,
      );
      expect(
        snapshot.toolAvailability('share_content'),
        CapabilityAvailability.unknown,
      );
    });
  });
}
