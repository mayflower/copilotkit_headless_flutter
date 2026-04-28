import '../agui/protocol/run_agent_input.dart';
import '../agui/transport/agent_transport.dart';
import '../features/tools/application/frontend_tool_registry.dart';
import '../features/tools/domain/frontend_tool.dart';

typedef CopilotActionHandler =
    Future<CopilotActionResult> Function(
      Map<String, Object?> args,
      CopilotActionExecutionContext context,
    );

enum CopilotActionAvailabilityMode { enabled, disabled, remote }

enum CopilotActionRenderMode { none, render, renderAndWaitForResponse }

enum CopilotActionParameterType {
  string,
  number,
  boolean,
  object,
  objectArray,
  stringArray,
  numberArray,
  booleanArray,
}

class CopilotActionExecutionContext {
  const CopilotActionExecutionContext({
    this.cancelToken,
    this.threadId,
    this.runId,
    this.parentRunId,
    this.idToken,
    this.metadata = const <String, Object?>{},
  });

  final AgUiTransportCancellationToken? cancelToken;
  final String? threadId;
  final String? runId;
  final String? parentRunId;
  final String? idToken;
  final Map<String, Object?> metadata;
}

class CopilotActionResult {
  const CopilotActionResult({this.payload = const <String, Object?>{}});

  final Object? payload;
}

class CopilotActionParameter {
  const CopilotActionParameter({
    required this.name,
    required this.type,
    this.description,
    this.required = true,
    this.enumValues = const <String>[],
    this.attributes = const <CopilotActionParameter>[],
  });

  final String name;
  final CopilotActionParameterType type;
  final String? description;
  final bool required;
  final List<String> enumValues;
  final List<CopilotActionParameter> attributes;

  Map<String, Object?> toJsonSchema() {
    final schema = <String, Object?>{
      ..._schemaForType(type),
      if (description != null) 'description': description,
      if (enumValues.isNotEmpty) 'enum': enumValues,
    };

    if (type == CopilotActionParameterType.object && attributes.isNotEmpty) {
      schema.addAll(_objectAttributesSchema(attributes));
    }

    if (type == CopilotActionParameterType.objectArray &&
        attributes.isNotEmpty) {
      schema['items'] = <String, Object?>{
        'type': 'object',
        ..._objectAttributesSchema(attributes),
      };
    }

    return schema;
  }
}

class CopilotAction {
  const CopilotAction({
    required this.name,
    required this.handler,
    this.description,
    this.parameters = const <CopilotActionParameter>[],
    this.available = CopilotActionAvailabilityMode.enabled,
    this.followUp = true,
    this.renderMode = CopilotActionRenderMode.none,
    this.requiredPermissions = const <String>{},
  });

  final String name;
  final String? description;
  final List<CopilotActionParameter> parameters;
  final CopilotActionAvailabilityMode available;
  final bool followUp;
  final CopilotActionRenderMode renderMode;
  final Set<String> requiredPermissions;
  final CopilotActionHandler handler;

  Map<String, Object?> get parametersSchema {
    final requiredParameters = parameters
        .where((parameter) => parameter.required)
        .map((parameter) => parameter.name)
        .toList(growable: false);

    return <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        for (final parameter in parameters)
          parameter.name: parameter.toJsonSchema(),
      },
      if (requiredParameters.isNotEmpty) 'required': requiredParameters,
      'additionalProperties': false,
      'x-copilotkit': <String, Object?>{
        'available': available.name,
        'followUp': followUp,
        'renderMode': renderMode.name,
      },
    };
  }

  AgUiToolDefinition toToolDefinition() {
    return AgUiToolDefinition(
      name: name,
      description: description ?? '',
      parameters: parametersSchema,
    );
  }

  FrontendTool asFrontendTool() => _CopilotActionFrontendTool(this);
}

class CopilotActionRegistry {
  CopilotActionRegistry({Iterable<CopilotAction> actions = const []})
    : _actions = <String, CopilotAction>{
        for (final action in actions) action.name: action,
      };

  final Map<String, CopilotAction> _actions;

  List<CopilotAction> get actions =>
      List<CopilotAction>.unmodifiable(_actions.values);

  void register(CopilotAction action) {
    _actions[action.name] = action;
  }

  bool unregister(String name) => _actions.remove(name) != null;

  CopilotAction? actionNamed(String name) => _actions[name];

  FrontendToolRegistry toFrontendToolRegistry() {
    return FrontendToolRegistry(
      tools: _actions.values
          .map((action) => action.asFrontendTool())
          .toList(growable: false),
    );
  }

  List<AgUiToolDefinition> exportAvailableTools(
    FrontendToolAvailabilityContext context,
  ) {
    return toFrontendToolRegistry().exportAvailableTools(context);
  }
}

class _CopilotActionFrontendTool extends FrontendTool {
  const _CopilotActionFrontendTool(this.action);

  final CopilotAction action;

  @override
  String? get description => action.description;

  @override
  String get name => action.name;

  @override
  Map<String, Object?> get parametersSchema => action.parametersSchema;

  @override
  bool get canExecuteLocally =>
      action.available != CopilotActionAvailabilityMode.remote;

  @override
  bool get shouldFollowUp => action.followUp;

  @override
  FrontendToolRenderMode get renderMode {
    return switch (action.renderMode) {
      CopilotActionRenderMode.none => FrontendToolRenderMode.none,
      CopilotActionRenderMode.render => FrontendToolRenderMode.render,
      CopilotActionRenderMode.renderAndWaitForResponse =>
        FrontendToolRenderMode.renderAndWaitForResponse,
    };
  }

  @override
  FrontendToolAvailability availability(
    FrontendToolAvailabilityContext context,
  ) {
    if (action.available == CopilotActionAvailabilityMode.disabled) {
      return const FrontendToolAvailability.disabledByCapability(
        'Action is disabled.',
      );
    }

    return evaluateFrontendToolAvailability(
      context: context,
      toolName: action.name,
      requiredPermissions: action.requiredPermissions,
    );
  }

  @override
  Future<FrontendToolExecutionResult> execute(
    Map<String, Object?> args, {
    required FrontendToolExecutionContext context,
    AgUiTransportCancellationToken? cancelToken,
  }) async {
    final result = await action.handler(
      args,
      CopilotActionExecutionContext(
        cancelToken: cancelToken,
        threadId: context.threadId,
        runId: context.runId,
        parentRunId: context.parentRunId,
        idToken: context.idToken,
        metadata: context.metadata,
      ),
    );
    return FrontendToolExecutionResult(payload: result.payload);
  }
}

Map<String, Object?> _schemaForType(CopilotActionParameterType type) {
  return switch (type) {
    CopilotActionParameterType.string => const <String, Object?>{
      'type': 'string',
    },
    CopilotActionParameterType.number => const <String, Object?>{
      'type': 'number',
    },
    CopilotActionParameterType.boolean => const <String, Object?>{
      'type': 'boolean',
    },
    CopilotActionParameterType.object => const <String, Object?>{
      'type': 'object',
    },
    CopilotActionParameterType.objectArray => const <String, Object?>{
      'type': 'array',
      'items': <String, Object?>{'type': 'object'},
    },
    CopilotActionParameterType.stringArray => const <String, Object?>{
      'type': 'array',
      'items': <String, Object?>{'type': 'string'},
    },
    CopilotActionParameterType.numberArray => const <String, Object?>{
      'type': 'array',
      'items': <String, Object?>{'type': 'number'},
    },
    CopilotActionParameterType.booleanArray => const <String, Object?>{
      'type': 'array',
      'items': <String, Object?>{'type': 'boolean'},
    },
  };
}

Map<String, Object?> _objectAttributesSchema(
  List<CopilotActionParameter> attributes,
) {
  final requiredAttributes = attributes
      .where((attribute) => attribute.required)
      .map((attribute) => attribute.name)
      .toList(growable: false);

  return <String, Object?>{
    'properties': <String, Object?>{
      for (final attribute in attributes)
        attribute.name: attribute.toJsonSchema(),
    },
    if (requiredAttributes.isNotEmpty) 'required': requiredAttributes,
  };
}
