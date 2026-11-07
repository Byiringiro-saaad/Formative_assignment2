import 'package:flutter/material.dart';

/// Colour palette taken from the provided UI mockups.
class AppColors {
  const AppColors._();

  // Brand
  static const primary = Color(0xFF6C4DF6);
  static const primaryDark = Color(0xFF5135D8);
  static const primaryLight = Color(0xFFEEE9FF);
  static const heroStart = Color(0xFF7B5CFA);
  static const heroEnd = Color(0xFFA48BFF);

  // Surfaces
  static const background = Color(0xFFF7F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE6E4EF);

  // Text
  static const textPrimary = Color(0xFF1F1B2E);
  static const textSecondary = Color(0xFF6B6880);
  static const textMuted = Color(0xFF9D9AB0);

  // Status: Submitted
  static const submitted = Color(0xFFC98A00);
  static const submittedBg = Color(0xFFFFF4D6);

  // Status: In progress
  static const inProgress = Color(0xFF6C4DF6);
  static const inProgressBg = Color(0xFFEEE9FF);

  // Status: Resolved
  static const resolved = Color(0xFF2E9E4F);
  static const resolvedBg = Color(0xFFE3F6E8);

  // Feedback
  static const danger = Color(0xFFE5484D);
  static const dangerBg = Color(0xFFFDECEC);

  // Summary tiles
  static const tileBlue = Color(0xFFEAF3FF);
  static const tileBlueIcon = Color(0xFF2F80ED);
}
