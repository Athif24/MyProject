import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_radius.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';

/// Kartu proyek pada seksi Projects di Beranda.
class ProjectCard extends StatelessWidget {
  final ProjectWithCounts item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final project = item.project;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _DateChip(
                label: IdDate.range(project.startDate, project.dueDate),
              ),
              const Spacer(),
              _ProjectMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: AppSizes.cardGap),
          Text(
            project.title,
            style: AppTypography.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.cardGap),
          Row(
            children: [
              _MetaCount(
                icon: AppIcons.check,
                label: AppStrings.taskCount(item.taskCount),
              ),
              const SizedBox(width: AppSizes.cardGap),
              _MetaCount(
                icon: AppIcons.folder,
                label: AppStrings.subtaskCount(item.subtaskCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;

  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navActiveBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _MetaCount extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaCount({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: AppColors.textMuted),
        const SizedBox(width: AppSizes.itemSpacing),
        Text(label, style: AppTypography.textTheme.bodySmall),
      ],
    );
  }
}

class _ProjectMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProjectMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: AppStrings.projectMenu,
      icon: const Icon(
        AppIcons.more,
        color: AppColors.textMuted,
        size: 22,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Text(
            AppStrings.edit,
            style: AppTypography.textTheme.labelLarge,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            AppStrings.delete,
            style: AppTypography.textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}
