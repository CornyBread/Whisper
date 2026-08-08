import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Labelled text field matching the mockups: 54dp height, surface background,
/// rounded 16dp corners, optional password toggle and inline error text.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: hasError ? AppColors.rose : AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: widget.controller,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              widget.errorText!,
              style: const TextStyle(fontSize: 12, color: AppColors.rose, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
