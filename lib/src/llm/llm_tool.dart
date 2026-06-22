/// Tool schema exposed to an LLM adapter.
class LlmTool {
  /// Creates an LLM tool schema.
  const LlmTool({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// Tool/function name.
  final String name;

  /// Human-readable tool description.
  final String description;

  /// JSON schema for tool parameters.
  final Map<String, Object?> parameters;

  /// Converts this tool into OpenAI Chat Completions format.
  Map<String, Object?> toOpenAIToolJson() {
    return <String, Object?>{
      'type': 'function',
      'function': <String, Object?>{
        'name': name,
        'description': description,
        'parameters': parameters,
      },
    };
  }
}

/// Tools the copilot model may call.
const copilotTools = <LlmTool>[
  LlmTool(
    name: 'tap',
    description: 'Tap a visible UI node by id.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
      },
      'required': <String>['id'],
    },
  ),
  LlmTool(
    name: 'type_text',
    description: 'Enter text into a text field node.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
        'text': <String, Object?>{'type': 'string'},
      },
      'required': <String>['id', 'text'],
    },
  ),
  LlmTool(
    name: 'scroll',
    description: 'Scroll a scrollable node.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
        'direction': <String, Object?>{
          'type': 'string',
          'enum': <String>['up', 'down', 'left', 'right'],
        },
        'amount': <String, Object?>{
          'type': 'string',
          'enum': <String>['small', 'medium', 'large'],
        },
      },
      'required': <String>['id', 'direction'],
    },
  ),
  LlmTool(
    name: 'wait',
    description: 'Wait for loading, animation, or async UI state.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'duration_ms': <String, Object?>{'type': 'integer'},
      },
    },
  ),
  LlmTool(
    name: 'done',
    description: 'Finish when the user goal is complete.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'summary': <String, Object?>{'type': 'string'},
      },
      'required': <String>['summary'],
    },
  ),
  LlmTool(
    name: 'fail',
    description: 'Stop when the goal cannot be completed.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'reason': <String, Object?>{'type': 'string'},
      },
      'required': <String>['reason'],
    },
  ),
];
