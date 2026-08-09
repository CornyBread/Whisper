import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Inline banner for form-level feedback: a failed request (401/409/429/5xx)
/// or a confirmation after a successful one.
class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.rose : AppColors.mint;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
