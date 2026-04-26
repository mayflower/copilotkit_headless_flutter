import '../transport/agent_transport.dart';

enum CapabilityAvailability { unknown, unavailable, available }

class CapabilitySnapshot {
  const CapabilitySnapshot({
    this.frontendTools = CapabilityAvailability.unknown,
    this.resume = CapabilityAvailability.unknown,
    this.reasoning = CapabilityAvailability.unknown,
    this.multimodalInput = CapabilityAvailability.unknown,
    this.toolCapabilities = const <String, CapabilityAvailability>{},
  });

  const CapabilitySnapshot.unknown()
    : frontendTools = CapabilityAvailability.unknown,
      resume = CapabilityAvailability.unknown,
      reasoning = CapabilityAvailability.unknown,
      multimodalInput = CapabilityAvailability.unknown,
      toolCapabilities = const <String, CapabilityAvailability>{};

  final CapabilityAvailability frontendTools;
  final CapabilityAvailability resume;
  final CapabilityAvailability reasoning;
  final CapabilityAvailability multimodalInput;
  final Map<String, CapabilityAvailability> toolCapabilities;

  CapabilityAvailability toolAvailability(String toolName) {
    return toolCapabilities[toolName] ?? CapabilityAvailability.unknown;
  }
}

class CapabilityService {
  const CapabilityService();

  CapabilitySnapshot parse(Map<String, Object?> rawPayload) {
    final features = _readObject(rawPayload['features']);
    final tools = _readObject(rawPayload['tools']);
    return CapabilitySnapshot(
      frontendTools: _availabilityFromValue(features['frontend_tools']),
      resume: _availabilityFromValue(features['resume']),
      reasoning: _availabilityFromValue(features['reasoning']),
      multimodalInput: _availabilityFromValue(features['multimodal_input']),
      toolCapabilities: <String, CapabilityAvailability>{
        for (final entry in tools.entries)
          entry.key: _availabilityFromValue(entry.value),
      },
    );
  }

  CapabilitySnapshot fromTransport(AgUiCapabilitySet transportCapabilities) {
    return CapabilitySnapshot(
      frontendTools: transportCapabilities.supportsFrontendTools
          ? CapabilityAvailability.available
          : CapabilityAvailability.unavailable,
      resume: transportCapabilities.supportsResume
          ? CapabilityAvailability.available
          : CapabilityAvailability.unavailable,
      toolCapabilities: <String, CapabilityAvailability>{
        for (final toolName in transportCapabilities.supportedFrontendTools)
          toolName: CapabilityAvailability.available,
      },
    );
  }
}

CapabilityAvailability _availabilityFromValue(Object? value) {
  return switch (value) {
    true => CapabilityAvailability.available,
    false => CapabilityAvailability.unavailable,
    _ => CapabilityAvailability.unknown,
  };
}

Map<String, Object?> _readObject(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entryValue) => MapEntry(key.toString(), entryValue));
  }
  return const <String, Object?>{};
}
