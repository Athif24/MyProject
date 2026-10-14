import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';

/// Pill filter dengan menu dropdown. Dipakai untuk filter periode Overview dan
/// filter waktu pada seksi Projects.
class HomeFilterDropdown<T> extends StatelessWidget {
  final List<T> options;
  final T value;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final String semanticLabel;

  const HomeFilterDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PopupMenuButton<T>(
        tooltip: semanticLabel,
        onSelected: onChanged,
        position: PopupMenuPosition.under,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        itemBuilder: (context) => [
          for (final option in options)
            PopupMenuItem<T>(
              value: option,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labelOf(option),
                      style: AppTypography.textTheme.labelLarge,
                    ),
                  ),
                  if (option == value)
                    const Icon(
                      AppIcons.check,
                      size: AppSizes.iconSmall,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(labelOf(value), style: AppTypography.textTheme.labelLarge),
              const SizedBox(width: AppSizes.itemSpacing),
              const Icon(
                AppIcons.dropdown,
                size: AppSizes.iconSmall,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
