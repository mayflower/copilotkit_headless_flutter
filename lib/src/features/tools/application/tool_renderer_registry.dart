class ToolRenderer {
  const ToolRenderer({required this.id});

  final String id;
}

class ToolRendererRegistry {
  const ToolRendererRegistry({
    required this.defaultRenderer,
    this.renderers = const <String, ToolRenderer>{},
  });

  final ToolRenderer defaultRenderer;
  final Map<String, ToolRenderer> renderers;

  ToolRenderer resolve(String toolName) {
    return renderers[toolName] ?? defaultRenderer;
  }
}
