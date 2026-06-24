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
    name: 'long_press',
    description: 'Long-press a visible UI node by id.',
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
    description:
        'Enter text into a text field node. Prefer replace_text when the existing value should be overwritten.',
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
    name: 'clear_text',
    description: 'Clear all text from a visible text field node.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
      },
      'required': <String>['id'],
    },
  ),
  LlmTool(
    name: 'replace_text',
    description: 'Replace all text in a visible text field node.',
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
    name: 'set_text_selection',
    description:
        'Set the selection range in a visible text field node using zero-based offsets.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
        'start': <String, Object?>{
          'type': 'integer',
          'minimum': 0,
        },
        'end': <String, Object?>{
          'type': 'integer',
          'minimum': 0,
        },
      },
      'required': <String>['id', 'start', 'end'],
    },
  ),
  LlmTool(
    name: 'keyboard_action',
    description:
        'Send one keyboard action to the focused input. Use only when a text field or keyboard interaction is clearly active.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'key': <String, Object?>{
          'type': 'string',
          'enum': <String>[
            'backspace',
            'delete',
            'enter',
            'done',
            'submit',
            'search',
            'go',
            'next',
            'previous',
            'escape',
            'tab',
            'shift_tab',
            'select_all',
          ],
        },
      },
      'required': <String>['key'],
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
    name: 'drag',
    description:
        'Drag across a visible node. Use for sliders, swipe buttons, swipe-to-dismiss, carousels, maps, and pull-to-refresh when semantics are insufficient.',
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
    name: 'long_press_drag',
    description:
        'Long-press a visible node, then drag. Use for reorder handles, drag handles, and controls that require press-and-hold before moving.',
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
    name: 'slider_to_value',
    description:
        'Drag a slider-like control to a normalized value from 0.0 to 1.0.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
        'value': <String, Object?>{
          'type': 'number',
          'minimum': 0,
          'maximum': 1,
        },
      },
      'required': <String>['id', 'value'],
    },
  ),
  LlmTool(
    name: 'adjust_value',
    description:
        'Use semantic increase/decrease on a value control such as a slider or stepper.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
        'direction': <String, Object?>{
          'type': 'string',
          'enum': <String>['increase', 'decrease'],
        },
        'steps': <String, Object?>{
          'type': 'integer',
          'minimum': 1,
          'maximum': 20,
        },
      },
      'required': <String>['id', 'direction'],
    },
  ),
  LlmTool(
    name: 'dismiss',
    description:
        'Dismiss a visible dismissible node. Uses semantic dismiss when exposed, otherwise falls back to dragging the node left.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'id': <String, Object?>{'type': 'string'},
      },
      'required': <String>['id'],
    },
  ),
  LlmTool(
    name: 'system_back',
    description:
        'Request system back navigation. Use only when no text input is focused and the goal clearly requires leaving the current route/dialog.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{},
    },
  ),
  LlmTool(
    name: 'request_confirmation',
    description:
        'Ask the app/user for approval before continuing with a sensitive, risky, destructive, payment, privacy, account, or irreversible step.',
    parameters: <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'reason': <String, Object?>{'type': 'string'},
      },
      'required': <String>['reason'],
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
