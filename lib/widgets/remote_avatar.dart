import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular avatar backed by an uploaded picture, falling back to initials.
///
/// [localFile] wins over [imageUrl] so a freshly picked photo can be previewed
/// before it is uploaded.
class RemoteAvatar extends StatelessWidget {
  const RemoteAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.localFile,
    this.size = 52,
    this.backgroundColor = AppColors.lavender,
  });

  final String initials;
  final String? imageUrl;
  final File? localFile;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (localFile != null) {
      child = Image.file(localFile!, width: size, height: size, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A broken or unreachable upload must not take the screen down with it.
        errorBuilder: (context, error, stackTrace) => _initialsBox,
      );
    } else {
      child = _initialsBox;
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: child));
  }

  Widget get _initialsBox => Container(
        width: size,
        height: size,
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.panel,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.34,
          ),
        ),
      );
}
