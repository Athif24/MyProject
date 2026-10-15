import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/core/widgets/section_header.dart';
import 'package:sync_daily/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:sync_daily/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_add_button.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_item_tile.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

/// Layar Kalender (F5): grid bulan + agenda tanggal terpilih.
///
/// TODO(design): tinggi sel, jarak antar sel, dan gaya titik mengikuti token
/// theme karena DESIGN.md hanya menyebut garis besarnya ("hari terpilih
/// lingkaran hitam, titik kecil berwarna untuk hari yang punya item").
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarCubit(
        taskRepository: getIt<TaskRepository>(),
      )..start(),
      child: const _CalendarView(),
    );
  }
}

/// Jarak bawah agar item terakhir tidak tertutup bottom nav.
const double _bottomInset = AppSizes.navHeight + AppSizes.sectionGap * 2;

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  /// Membuka detail item yang dipilih di Kalender.
  void _openDetail(BuildContext context, Task task) {
    context.push<List<String>>('/tasks/${task.id}');
  }

  /// Membuka form "Buat baru" dengan tanggal terpilih sudah terisi.
  void _openNewItem(BuildContext context, DateTime date) {
    context.push('/tasks/new?date=${_isoDate(date)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayarLatar(
        child: SafeArea(
          child: BlocBuilder<CalendarCubit, CalendarState>(
            builder: (context, state) {
              switch (state.status) {
                case CalendarStatus.loading:
                  return const Center(child: CircularProgressIndicator());
                case CalendarStatus.error:
                  return _ErrorState(
                    onRetry: () => context.read<CalendarCubit>().retry(),
                  );
                case CalendarStatus.loaded:
                  return _LoadedView(
                    state: state,
                    onSelectDate: context.read<CalendarCubit>().selectDate,
                    onPreviousMonth: context.read<CalendarCubit>().previousMonth,
                    onNextMonth: context.read<CalendarCubit>().nextMonth,
                    onAdd: () => _openNewItem(context, state.selectedDate),
                    onOpenDetail: (task) => _openDetail(context, task),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final CalendarState state;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onAdd;
  final ValueChanged<Task> onOpenDetail;

  const _LoadedView({
    required this.state,
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onAdd,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.cardGap,
        AppSizes.pagePadding,
        _bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.screenCalendar,
            style: AppTypography.textTheme.displayMedium,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          CalendarMonthGrid(
            month: state.visibleMonth,
            selectedDate: state.selectedDate,
            daysWithItems: state.daysWithItems,
            onSelectDate: onSelectDate,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          SectionHeader(
            title: _sectionTitle(state),
            trailing: CalendarAddButton(onTap: onAdd),
          ),
          const SizedBox(height: AppSizes.cardGap),
          _Agenda(
            state: state,
            onOpenDetail: onOpenDetail,
          ),
        ],
      ),
    );
  }
}

/// Judul seksi: `Tugas Hari Ini` bila tanggal terpilih hari ini, selain itu
/// `Tugas 14 Okt`.
String _sectionTitle(CalendarState state) {
  if (state.isToday(state.selectedDate)) {
    return AppStrings.calendarTodaySection;
  }
  return AppStrings.calendarDateSection(IdDate.dayMonth(state.selectedDate));
}

class _Agenda extends StatelessWidget {
  final CalendarState state;
  final ValueChanged<Task> onOpenDetail;

  const _Agenda({required this.state, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    if (state.agenda.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sectionGap),
        child: EmptyState(
          title: AppStrings.noItemsOnDay,
          description: AppStrings.noItemsOnDayDescription,
        ),
      );
    }

    return Column(
      children: [
        for (final entry in state.agenda) ...[
          CalendarItemTile(
            entry: entry,
            onTap: () => onOpenDetail(entry.task),
          ),
          if (entry != state.agenda.last)
            const SizedBox(height: AppSizes.itemSpacing),
        ],
      ],
    );
  }
}

/// Tanggal ISO (`YYYY-MM-DD`) untuk parameter `?date=` pada rute form.
String _isoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: EmptyState(
          title: AppStrings.loadFailedTitle,
          description: AppStrings.loadFailedDescription,
          action: FilledButton(
            onPressed: onRetry,
            child: Text(
              AppStrings.retry,
              style: AppTypography.textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }
}
