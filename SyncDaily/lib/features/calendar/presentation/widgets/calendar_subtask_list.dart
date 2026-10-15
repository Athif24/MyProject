import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Daftar kecil sub-tugas di dalam kartu induknya pada agenda Kalender.
///
/// Tiap baris: penanda selesai/belum + judul sub-tugas (bercoret bila selesai),
/// penanda sejajar tengah dengan judulnya. Urutannya sama dengan layar detail.
/// Daftar ini hanya tampil saat kartu induknya dibuka lewat baris panah, dan
/// seluruh areanya (seperti bagian lain kartu) membuka detail induk.
///
/// TODO(design): DESIGN.md baru menyebut aturan satu kartu dengan panah di
/// dasar; rincian gaya barisnya memakai token theme yang ada.
class CalendarSubtaskList extends StatelessWidget {
  final List<Task> subtasks;

  const CalendarSubtaskList({super.key, required this.subtasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final subtask in subtasks) _SubtaskRow(subtask: subtask),
      ],
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final Task subtask;

  const _SubtaskRow({required this.subtask});

  @override
  Widget build(BuildContext context) {
    final isDone = subtask.status == TaskStatus.done;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.calendarSubtaskGap),
      child: Row(
        children: [
          Semantics(
            label: isDone ? AppStrings.statusDone : AppStrings.statusNotDone,
            child: Icon(
              isDone ? AppIcons.checkCircle : AppIcons.circle,
              size: AppSizes.iconSmall,
              color: isDone ? AppColors.primaryDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSizes.calendarSubtaskGap),
          Expanded(
            child: Text(
              subtask.title,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: isDone ? AppColors.textMuted : null,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
