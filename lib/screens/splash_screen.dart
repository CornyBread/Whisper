import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown while [AuthController.restoreSession] decides where to send the user.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.lavender),
        ),
      ),
    );
  }
}
