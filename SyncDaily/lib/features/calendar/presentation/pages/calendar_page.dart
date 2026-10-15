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
import 'package:sync_daily/features/tasks/presentation/widgets/task_detail_flow.dart';

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

/// Sisa ruang minimal untuk daftar agenda yang bergulir sendiri. Bila ruang di
/// layar lebih kecil dari ini (layar pendek), seluruh halaman bergulir seperti
/// sebelumnya supaya tidak ada isi yang terpotong.
const double _minAgendaHeight = 160;

class _CalendarView extends StatelessWidget {
  const _CalendarView();

  /// Membuka detail item yang dipilih di Kalender. Bila item dihapus di sana,
  /// kembali ke Kalender dan tampilkan snackbar "Urungkan" seperti di daftar
  /// tugas.
  Future<void> _openDetail(BuildContext context, Task task) {
    return openTaskDetailWithUndo(
      context: context,
      taskId: task.id,
      onUndo: context.read<CalendarCubit>().restore,
    );
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
                    onToggleSubtasks:
                        context.read<CalendarCubit>().toggleSubtasks,
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Isi Kalender yang sudah termuat.
///
/// Grid bulan (termasuk nama bulan dan tombolnya), judul seksi, dan tombol
/// tambah tetap di atas; hanya daftar agenda yang bergulir. Bila sisa ruang
/// untuk daftar agenda terlalu kecil (< [_minAgendaHeight]), seluruh halaman
/// bergulir seperti sebelumnya supaya layar pendek tidak terpotong.
class _LoadedView extends StatefulWidget {
  final CalendarState state;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onAdd;
  final ValueChanged<Task> onOpenDetail;
  final ValueChanged<String> onToggleSubtasks;

  const _LoadedView({
    required this.state,
    required this.onSelectDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onAdd,
    required this.onOpenDetail,
    required this.onToggleSubtasks,
  });

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  /// Kunci bagian tetap untuk mengukur tingginya.
  final GlobalKey _fixedKey = GlobalKey();

  /// Tinggi bagian tetap hasil pengukuran, null sebelum frame pertama selesai.
  double? _fixedHeight;

  @override
  Widget build(BuildContext context) {
    _measureFixed();

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = _fixedHeight;
        final agendaSpace = height == null
            ? 0.0
            : constraints.maxHeight - height - AppSizes.cardGap;
        if (agendaSpace < _minAgendaHeight) {
          return _scrollingLayout();
        }
        return _fixedLayout();
      },
    );
  }

  /// Mengukur tinggi bagian tetap setelah frame selesai. Tinggi berubah hanya
  /// saat ukuran huruf atau lebar layar berubah, jadi tidak ada pengukuran
  /// berulang.
  void _measureFixed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final size = _fixedKey.currentContext?.size;
      if (size == null) {
        return;
      }
      final measured = size.height;
      final previous = _fixedHeight;
      if (previous != null && (previous - measured).abs() < 0.5) {
        return;
      }
      setState(() => _fixedHeight = measured);
    });
  }

  /// Bagian tetap: judul layar, grid bulan, dan judul seksi beserta tombol
  /// tambah.
  Widget _fixedPart() {
    return KeyedSubtree(
      key: _fixedKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.screenCalendar,
            style: AppTypography.textTheme.displayMedium,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          CalendarMonthGrid(
            month: widget.state.visibleMonth,
            selectedDate: widget.state.selectedDate,
            daysWithItems: widget.state.daysWithItems,
            onSelectDate: widget.onSelectDate,
            onPreviousMonth: widget.onPreviousMonth,
            onNextMonth: widget.onNextMonth,
          ),
          const SizedBox(height: AppSizes.sectionGap),
          SectionHeader(
            title: _sectionTitle(widget.state),
            trailing: CalendarAddButton(onTap: widget.onAdd),
          ),
        ],
      ),
    );
  }

  Widget _agenda() {
    return _Agenda(
      state: widget.state,
      onOpenDetail: widget.onOpenDetail,
      onToggleSubtasks: widget.onToggleSubtasks,
    );
  }

  /// Bagian tetap di atas, daftar agenda bergulir sendiri di bawahnya.
  Widget _fixedLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.cardGap,
            AppSizes.pagePadding,
            0,
          ),
          child: _fixedPart(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              AppSizes.cardGap,
              AppSizes.pagePadding,
              _bottomInset,
            ),
            child: _agenda(),
          ),
        ),
      ],
    );
  }

  /// Layar pendek: seluruh halaman bergulir (perilaku lama).
  Widget _scrollingLayout() {
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
          _fixedPart(),
          const SizedBox(height: AppSizes.cardGap),
          _agenda(),
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
  final ValueChanged<String> onToggleSubtasks;

  const _Agenda({
    required this.state,
    required this.onOpenDetail,
    required this.onToggleSubtasks,
  });

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
            isSubtasksOpen: state.expandedCardIds.contains(entry.task.id),
            onToggleSubtasks: () => onToggleSubtasks(entry.task.id),
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
