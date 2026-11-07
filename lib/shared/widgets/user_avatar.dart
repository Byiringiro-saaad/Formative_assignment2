import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';

/// Circle with the user's initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 48});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroEnd],
        ),
      ),
      child: Text(
        user.initials.isEmpty ? '?' : user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
