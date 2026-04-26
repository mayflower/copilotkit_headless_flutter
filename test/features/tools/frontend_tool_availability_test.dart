import 'package:flutter_test/flutter_test.dart';
import 'package:copilotkit_headless_flutter/src/agui/capabilities/capability_service.dart';
import 'package:copilotkit_headless_flutter/src/agui/transport/agent_transport.dart';
import 'package:copilotkit_headless_flutter/src/features/tools/domain/frontend_tool.dart';

void main() {
  group('FrontendTool availability', () {
    test(
      'permission and capability changes alter availability predictably',
      () {
        const tool = _PermissionGatedTool();

        final disabledByCapability = tool.availability(
          const FrontendToolAvailabilityContext(
            capabilities: CapabilitySnapshot(
              frontendTools: CapabilityAvailability.unavailable,
              toolCapabilities: <String, CapabilityAvailability>{
                'secure_copy': CapabilityAvailability.available,
              },
            ),
          ),
        );
        expect(
          disabledByCapability.status,
          FrontendToolAvailabilityStatus.disabledByCapability,
        );

        final missingPermission = tool.availability(
          const FrontendToolAvailabilityContext(
            capabilities: CapabilitySnapshot(
              frontendTools: CapabilityAvailability.available,
              toolCapabilities: <String, CapabilityAvailability>{
                'secure_copy': CapabilityAvailability.available,
              },
            ),
          ),
        );
        expect(
          missingPermission.status,
          FrontendToolAvailabilityStatus.missingPermission,
        );

        final available = tool.availability(
          const FrontendToolAvailabilityContext(
            capabilities: CapabilitySnapshot(
              frontendTools: CapabilityAvailability.available,
              toolCapabilities: <String, CapabilityAvailability>{
                'secure_copy': CapabilityAvailability.available,
              },
            ),
            grantedPermissions: <String>{'clipboard'},
          ),
        );
        expect(available.isAvailable, isTrue);
      },
    );
  });
}

class _PermissionGatedTool extends FrontendTool {
  const _PermissionGatedTool();

  @override
  String get name => 'secure_copy';

  @override
  String? get description => 'Test-only permission gated tool.';

  @override
  Map<String, Object?> get parametersSchema => const <String, Object?>{};

  @override
  FrontendToolAvailability availability(
    FrontendToolAvailabilityContext context,
  ) {
    return evaluateFrontendToolAvailability(
      context: context,
      toolName: name,
      requiredPermissions: const <String>{'clipboard'},
    );
  }

  @override
  Future<FrontendToolExecutionResult> execute(
    Map<String, Object?> args, {
    required FrontendToolExecutionContext context,
    AgUiTransportCancellationToken? cancelToken,
  }) async {
    return const FrontendToolExecutionResult();
  }
}
