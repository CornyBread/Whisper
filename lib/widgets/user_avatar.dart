import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

/// Circular avatar showing a user's initials on their assigned color.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 52});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: user.avatarColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: TextStyle(
          color: AppColors.panel,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
