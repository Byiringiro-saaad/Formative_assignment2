import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Logo, title and subtitle at the top of the auth screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.heroStart, AppColors.heroEnd],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.campaign_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 24),
        Text(title, style: text.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
