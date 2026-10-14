import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';

class UnreadBadge extends StatelessWidget {
  final int count;
  final int maxCount;

  const UnreadBadge({
    super.key,
    required this.count,
    this.maxCount = 99,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final label = count > maxCount ? '$maxCount+' : '$count';

    return Semantics(
      label: '$count belum dibaca',
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSizes.unreadBadgeMin,
          minHeight: AppSizes.unreadBadgeMin,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: AppColors.surface,
          ),
        ),
      ),
    );
  }
}
