import 'dart:async';

import '../../test/flutter_test_config.dart' as app_fonts;

/// Same font setup as the tests, so screenshots use the real app font.
Future<void> testExecutable(FutureOr<void> Function() testMain) =>
    app_fonts.testExecutable(testMain);
