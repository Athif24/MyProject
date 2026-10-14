import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_typography.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.ink : AppColors.surface,
            border: Border.all(
              color: isActive ? Colors.transparent : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            label,
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: isActive ? AppColors.surface : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
