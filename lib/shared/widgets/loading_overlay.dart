import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Full-screen or overlay loading indicator with optional message.
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool fullscreen;

  const LoadingOverlay({
    super.key,
    this.message,
    this.fullscreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!, style: AppTextStyles.bodyMedium),
        ],
      ],
    );

    if (!fullscreen) return content;

    return Container(
      color: AppColors.background.withValues(alpha: 0.8),
      child: Center(child: content),
    );
  }
}
