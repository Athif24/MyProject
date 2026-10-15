import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';

class UnreadDot extends StatelessWidget {
  final double size;

  const UnreadDot({super.key, this.size = AppSizes.unreadDot});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.unreadIndicator,
      child: Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
