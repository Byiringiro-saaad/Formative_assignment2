import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's real fonts before any test runs, so text is measured the
/// same way as on a device (instead of the square "Ahem" test glyphs).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final jakarta = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    jakarta.addFont(_file('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await jakarta.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(_file(icons.path))).load();
    }
  }

  await testMain();
}

Future<ByteData> _file(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());
