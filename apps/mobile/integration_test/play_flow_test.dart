import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/play_flow_runner.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'End-to-end play flow: Welcome -> Home -> Play -> Now Playing -> ICY -> Library',
    runPlayFlowIntegrationTest,
  );
}
