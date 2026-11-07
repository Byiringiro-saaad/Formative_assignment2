import 'package:campus_incidents/app.dart';
import 'package:campus_incidents/core/theme/app_colors.dart';
import 'package:campus_incidents/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on the branded splash screen', (tester) async {
    await tester.pumpWidget(const CampusApp());

    expect(find.text('Campus Incidents'), findsOneWidget);
    expect(find.text('Report issues. Track their resolution.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('theme uses the brand colour and bundled font', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
  });
}
