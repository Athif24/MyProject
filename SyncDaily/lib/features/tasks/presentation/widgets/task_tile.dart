import 'package:flutter/material.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/widgets/list_item_tile.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/presentation/form/pages/task_form_page.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_date_label.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_labels.dart';

/// Item daftar tugas: judul, tipe, dan tanggal/jam saja.
///
/// TODO(design): layar daftar tugas belum didesain. Sementara ini menumpang
/// komponen `ListItemTile` yang sudah ada; ganti setelah desain tersedia.
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskTile({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.categoryColors;
    final category = taskCategoryFor(task.type);

    return ListItemTile(
      icon: taskIconFor(task.type),
      iconBackground: colors.backgroundFor(category),
      iconColor: colors.iconFor(category),
      title: task.title,
      subtitle: typeLabel(task.type),
      time: taskDateLabel(task),
      onTap: onTap,
    );
  }
}
