import 'package:flutter/widgets.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

import 'app/copilot_example_app.dart';
import 'services/copilot_service.dart';

void main() {
  runApp(
    CopilotApp(
      config: buildCopilotConfig(),
      child: const CopilotExampleApp(),
    ),
  );
}
