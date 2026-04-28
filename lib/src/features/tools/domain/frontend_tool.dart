import '../../../agui/capabilities/capability_service.dart';
import '../../../agui/protocol/run_agent_input.dart';
import '../../../agui/transport/agent_transport.dart';

enum FrontendToolAvailabilityStatus {
  available,
  disabledByCapability,
  missingPermission,
}

enum FrontendToolRenderMode { none, render, renderAndWaitForResponse }

class FrontendToolAvailability {
  const FrontendToolAvailability({required this.status, this.reason});

  const FrontendToolAvailability.available()
    : status = FrontendToolAvailabilityStatus.available,
      reason = null;

  const FrontendToolAvailability.disabledByCapability([this.reason])
    : status = FrontendToolAvailabilityStatus.disabledByCapability;

  const FrontendToolAvailability.missingPermission([this.reason])
    : status = FrontendToolAvailabilityStatus.missingPermission;

  final FrontendToolAvailabilityStatus status;
  final String? reason;

  bool get isAvailable => status == FrontendToolAvailabilityStatus.available;
}

class FrontendToolAvailabilityContext {
  const FrontendToolAvailabilityContext({
    this.capabilities = const CapabilitySnapshot.unknown(),
    this.grantedPermissions = const <String>{},
  });

  final CapabilitySnapshot capabilities;
  final Set<String> grantedPermissions;

  bool hasPermission(String permission) =>
      grantedPermissions.contains(permission);
}

class FrontendToolExecutionContext {
  const FrontendToolExecutionContext({
    this.threadId,
    this.runId,
    this.parentRunId,
    this.idToken,
    this.metadata = const <String, Object?>{},
  });

  final String? threadId;
  final String? runId;
  final String? parentRunId;
  final String? idToken;
  final Map<String, Object?> metadata;
}

class FrontendToolExecutionResult {
  const FrontendToolExecutionResult({this.payload = const <String, Object?>{}});

  final Object? payload;
}

abstract class FrontendTool {
  const FrontendTool();

  String get name;

  String? get description;

  Map<String, Object?> get parametersSchema;

  bool get canExecuteLocally => true;

  bool get shouldFollowUp => true;

  FrontendToolRenderMode get renderMode => FrontendToolRenderMode.none;

  bool get waitsForUserResponse =>
      renderMode == FrontendToolRenderMode.renderAndWaitForResponse;

  FrontendToolAvailability availability(
    FrontendToolAvailabilityContext context,
  );

  AgUiToolDefinition toDefinition() {
    return AgUiToolDefinition(
      name: name,
      description: description ?? '',
      parameters: parametersSchema,
    );
  }

  Future<FrontendToolExecutionResult> execute(
    Map<String, Object?> args, {
    required FrontendToolExecutionContext context,
    AgUiTransportCancellationToken? cancelToken,
  });
}

FrontendToolAvailability evaluateFrontendToolAvailability({
  required FrontendToolAvailabilityContext context,
  required String toolName,
  Set<String> requiredPermissions = const <String>{},
}) {
  // Missing capability data is treated as unavailable here on purpose so the
  // app only exports tools the current backend session explicitly supports.
  if (context.capabilities.frontendTools != CapabilityAvailability.available) {
    return const FrontendToolAvailability.disabledByCapability(
      'Frontend tools are not enabled for this session.',
    );
  }

  if (context.capabilities.toolAvailability(toolName) !=
      CapabilityAvailability.available) {
    return FrontendToolAvailability.disabledByCapability(
      'Tool "$toolName" is not enabled by the current capability set.',
    );
  }

  for (final permission in requiredPermissions) {
    if (!context.hasPermission(permission)) {
      return FrontendToolAvailability.missingPermission(
        'Missing permission "$permission".',
      );
    }
  }

  return const FrontendToolAvailability.available();
}
