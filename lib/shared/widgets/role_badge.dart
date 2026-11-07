import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/user_role.dart';

/// Small pill showing whether a user is a student or staff member.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final staff = role == UserRole.staff;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: staff ? AppColors.resolvedBg : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: staff ? AppColors.resolved : AppColors.primary,
        ),
      ),
    );
  }
}
