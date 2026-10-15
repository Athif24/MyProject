import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/widgets/list_item_tile.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_subtask_list.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/presentation/form/pages/task_form_page.dart'
    show typeLabel;
import 'package:sync_daily/features/tasks/presentation/widgets/task_date_label.dart'
    show clockLabel;
import 'package:sync_daily/features/tasks/presentation/widgets/task_labels.dart';

/// Lama animasi buka/tutup daftar sub-tugas kartu agenda.
const Duration _toggleDuration = Duration(milliseconds: 200);

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

/// Item daftar agenda Kalender: judul, tipe, jam, dan sub-tugasnya.
///
/// Item yang sudah selesai tetap tampil, dengan judul bercoret. Sub-tugas yang
/// muncul pada hari yang sama menyatu ke kartu induknya: SATU kartu dengan
/// bagian baris info, daftar sub-tugas yang hanya tampil saat dibuka, dan baris
/// panah ramping di dasar kartu. Kartu ini (kecuali baris panah) membuka detail
/// induk.
class CalendarItemTile extends StatelessWidget {
  final CalendarEntry entry;

  /// True bila daftar sub-tugas kartu ini sedang terbuka. Keadaan sesi di
  /// `CalendarCubit` (bukan dari database); bawaan tertutup.
  final bool isSubtasksOpen;

  final VoidCallback? onTap;

  /// Aksi baris panah: membuka atau menutup daftar sub-tugas.
  final VoidCallback? onToggleSubtasks;

  const CalendarItemTile({
    super.key,
    required this.entry,
    this.isSubtasksOpen = false,
    this.onTap,
    this.onToggleSubtasks,
  });

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final colors = context.categoryColors;
    final category = taskCategoryFor(task.type);
    final subtasks = entry.subtasks;
    final doneSubtasks =
        subtasks.where((subtask) => subtask.status == TaskStatus.done).length;

    return ListItemTile(
      icon: taskIconFor(task.type),
      iconBackground: colors.backgroundFor(category),
      iconColor: colors.iconFor(category),
      title: task.title,
      subtitle: subtasks.isEmpty
          ? typeLabel(task.type)
          : AppStrings.cardSubtasksSummary(
              typeLabel(task.type),
              doneSubtasks,
              subtasks.length,
            ),
      time: calendarTimeLabel(entry),
      isCompleted: task.status == TaskStatus.done,
      footer: subtasks.isEmpty
          ? null
          : _SubtasksSection(subtasks: subtasks, isOpen: isSubtasksOpen),
      bottomBar: subtasks.isEmpty
          ? null
          : _SubtasksToggleRow(
              isOpen: isSubtasksOpen,
              onTap: onToggleSubtasks,
            ),
      onTap: onTap,
    );
  }
}

/// Bagian tengah kartu: daftar sub-tugas yang hanya tampil saat kartu dibuka.
///
/// Saat tertutup, bagian ini tidak mengambil tinggi sama sekali sehingga kartu
/// bersub-tugas sama tinggi dengan kartu biasa ditambah baris panahnya.
/// Padding di sini ikut beranimasi karena pemanggil yang mengatur jarak.
class _SubtasksSection extends StatelessWidget {
  final List<Task> subtasks;
  final bool isOpen;

  const _SubtasksSection({required this.subtasks, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _toggleDuration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isOpen
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.cardPadding,
                0,
                AppSizes.cardPadding,
                AppSizes.cardPadding,
              ),
              child: CalendarSubtaskList(subtasks: subtasks),
            )
          : const SizedBox(height: 0),
    );
  }
}

/// Baris ramping di dasar kartu berisi panah buka/tutup daftar sub-tugas.
///
/// Area sentuhnya selebar kartu dan setinggi [AppSizes.minTouchTarget] (44 dp)
/// supaya nyaman ditekan walau tampilannya hanya satu ikon kecil.
class _SubtasksToggleRow extends StatelessWidget {
  final bool isOpen;
  final VoidCallback? onTap;

  const _SubtasksToggleRow({required this.isOpen, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSizes.minTouchTarget,
        child: Center(
          child: AnimatedRotation(
            turns: isOpen ? 0.5 : 0,
            duration: _toggleDuration,
            curve: Curves.easeInOut,
            child: Icon(
              AppIcons.expand,
              size: AppSizes.calendarArrowIcon,
              color: AppColors.textMuted,
              semanticLabel: isOpen
                  ? AppStrings.hideSubtasks
                  : AppStrings.showSubtasks,
            ),
          ),
        ),
      ),
    );
  }
}
