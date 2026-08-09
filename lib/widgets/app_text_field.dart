import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  /// Read-only fields (e.g. an email the API will not let you change) are
  /// dimmed and skipped by focus traversal.
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isSingleLine = widget.obscureText || widget.maxLines == 1;
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
            focusNode: widget.focusNode,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            inputFormatters: widget.inputFormatters,
            enabled: widget.enabled,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.minLines,
            // Without this the text hugs the top of a single-line field: the
            // password field's suffix icon makes the decorator taller than the
            // text row, and `isDense` then aligns the text to the top of it.
            textAlignVertical: isSingleLine ? TextAlignVertical.center : TextAlignVertical.top,
            style: TextStyle(
              fontSize: 15,
              color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              // Keeps the eye button from imposing its 48dp default and
              // stretching the row taller than the 54dp the mockups call for.
              suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      visualDensity: VisualDensity.compact,
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
