import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shows a short message at the bottom of the screen.
void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.textPrimary,
      ),
    );
}
