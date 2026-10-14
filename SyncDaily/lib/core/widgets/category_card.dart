import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/theme/category_theme.dart';

class CategoryCard extends StatelessWidget {
  final TaskCategory category;
  final String title;
  final String? subtitle;
  final String? label;

  const CategoryCard({
    super.key,
    required this.category,
    required this.title,
    this.subtitle,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.categoryColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundFor(category),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                label!.toUpperCase(),
                style: AppTypography.textTheme.labelSmall,
              ),
            ),
          if (label != null) const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
