import 'package:flutter_test/flutter_test.dart';

import 'helpers/play_flow_runner.dart';

void main() {
  testWidgets(
    'End-to-end play flow: Welcome -> Home -> Play -> Now Playing -> ICY -> Library',
    runPlayFlowIntegrationTest,
  );
}
