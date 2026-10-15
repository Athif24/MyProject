import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_colors.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/theme/category_theme.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/features/calendar/domain/calendar_grid.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_labels.dart';

/// Grid bulan Kalender: judul bulan + tombol pindah bulan, kepala hari, dan
/// sel tanggal 6 baris x 7 kolom (awal pekan Senin).
///
/// TODO(design): rincian visual grid bulan (kepala hari, ukuran lingkaran hari
/// terpilih, besar titik) belum ada di DESIGN.md; sementara memakai token theme.
class CalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;

  /// Hari yang punya item beserta tipe itemnya (kunci: tanggal tanpa jam).
  final Map<DateTime, Set<TaskType>> daysWithItems;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.daysWithItems,
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = CalendarGrid.weeks(month);
    final headerDays = weeks.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthHeader(
          month: month,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
        ),
        const SizedBox(height: AppSizes.cardGap),
        Row(
          children: [
            for (final day in headerDays)
              Expanded(
                child: Text(
                  IdDate.weekdayShort(day.date),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.labelSmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.itemSpacing),
        for (final week in weeks)
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: CalendarDayCell(
                    day: day,
                    isSelected: _isSameDay(day.date, selectedDate),
                    categories: _categoriesFor(day.date),
                    onTap: () => onSelectDate(day.date),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// Warna titik mengikuti urutan tetap agar tampilan tidak berubah-ubah.
  List<TaskCategory> _categoriesFor(DateTime date) {
    final types = daysWithItems[dateOnly(date)];
    if (types == null || types.isEmpty) {
      return const [];
    }
    return [
      for (final type in const [
        TaskType.task,
        TaskType.event,
        TaskType.reminder,
        TaskType.milestone,
      ])
        if (types.contains(type)) taskCategoryFor(type),
    ];
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _MonthHeader({
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(
          icon: AppIcons.chevronLeft,
          semanticLabel: AppStrings.previousMonth,
          onTap: onPreviousMonth,
        ),
        Expanded(
          child: Center(
            child: Text(
              IdDate.monthYear(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.headlineMedium,
            ),
          ),
        ),
        AppIconButton(
          icon: AppIcons.chevronRight,
          semanticLabel: AppStrings.nextMonth,
          onTap: onNextMonth,
        ),
      ],
    );
  }
}

/// Satu sel tanggal pada grid bulan.
class CalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isSelected;

  /// Kategori yang punya item pada hari ini (maksimal satu titik per kategori).
  final List<TaskCategory> categories;
  final VoidCallback onTap;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: IdDate.full(day.date),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: AppSizes.calendarCellHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: AppSizes.calendarDayCircle,
                width: AppSizes.calendarDayCircle,
                alignment: Alignment.center,
                decoration: isSelected
                    ? const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${day.date.day}',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: isSelected
                        ? AppColors.surface
                        : (day.isInMonth
                            ? AppColors.ink
                            : AppColors.textMuted),
                  ),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: AppSizes.calendarDotGap),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.calendarDotGap / 3,
                        ),
                        child: Container(
                          height: AppSizes.calendarDot,
                          width: AppSizes.calendarDot,
                          decoration: BoxDecoration(
                            color: context.categoryColors.iconFor(category),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
