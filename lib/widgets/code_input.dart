import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Digit boxes drawn over a single hidden text field — one field keeps paste,
/// autofill and backspace behaving normally, which per-box fields break.
///
/// Shared by account verification and the email-change flow.
class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    this.length = 6,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final int length;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(length, (index) {
            final text = controller.text;
            final filled = index < text.length;
            final isNext = index == text.length && focusNode.hasFocus;
            return Container(
              width: 46,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: hasError
                      ? AppColors.rose
                      : isNext
                          ? AppColors.lavender
                          : AppColors.border,
                  width: isNext ? 1.6 : 1,
                ),
              ),
              child: Text(
                filled ? text[index] : '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            );
          }),
        ),
        // Invisible but focusable and hit-testable, so tapping the boxes opens
        // the keyboard and typing lands in a single field.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: length,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              showCursor: false,
              onSubmitted: onSubmitted,
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }
}
