import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/widgets/list_item_tile.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/presentation/form/pages/task_form_page.dart'
    show typeLabel;
import 'package:sync_daily/features/tasks/presentation/widgets/task_date_label.dart'
    show clockLabel;
import 'package:sync_daily/features/tasks/presentation/widgets/task_labels.dart';

/// Label jam satu entri agenda Kalender.
///
/// - item tanpa jam / hari tengah acara lintas hari: `Sepanjang hari`;
/// - item satu hari: `09.00`;
/// - hari pertama acara lintas hari: `Mulai 09.00`;
/// - hari terakhir acara lintas hari: `Sampai 17.00`.
String? calendarTimeLabel(CalendarEntry entry) {
  final time = entry.time;
  switch (entry.timeKind) {
    case CalendarTimeKind.allDay:
      return AppStrings.allDay;
    case CalendarTimeKind.clock:
      return time == null ? null : clockLabel(time);
    case CalendarTimeKind.startsAt:
      return time == null ? null : AppStrings.startsAtTime(clockLabel(time));
    case CalendarTimeKind.endsAt:
      return time == null ? null : AppStrings.endsAtTime(clockLabel(time));
  }
}

/// Item daftar agenda Kalender: judul, tipe, dan jam.
///
/// Item yang sudah selesai tetap tampil, dengan judul bercoret.
class CalendarItemTile extends StatelessWidget {
  final CalendarEntry entry;
  final VoidCallback? onTap;

  const CalendarItemTile({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final colors = context.categoryColors;
    final category = taskCategoryFor(task.type);

    return ListItemTile(
      icon: taskIconFor(task.type),
      iconBackground: colors.backgroundFor(category),
      iconColor: colors.iconFor(category),
      title: task.title,
      subtitle: typeLabel(task.type),
      time: calendarTimeLabel(entry),
      isCompleted: task.status == TaskStatus.done,
      onTap: onTap,
    );
  }
}
