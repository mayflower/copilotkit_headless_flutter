import '../../../agui/protocol/run_agent_input.dart';
import '../domain/frontend_tool.dart';

class FrontendToolRegistry {
  FrontendToolRegistry({required List<FrontendTool> tools})
    : _tools = List<FrontendTool>.unmodifiable(tools);

  final List<FrontendTool> _tools;

  List<FrontendTool> get tools => _tools;

  FrontendTool? toolNamed(String name) {
    for (final tool in _tools) {
      if (tool.name == name) {
        return tool;
      }
    }
    return null;
  }

  List<AgUiToolDefinition> exportAvailableTools(
    FrontendToolAvailabilityContext context,
  ) {
    return _tools
        .where((tool) => tool.availability(context).isAvailable)
        .map((tool) => tool.toDefinition())
        .toList(growable: false);
  }
}
