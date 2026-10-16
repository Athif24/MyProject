import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/core/state/calendar_selection.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
import 'package:sync_daily/features/calendar/domain/calendar_grid.dart';
import 'package:sync_daily/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

/// Cubit layar Kalender (F5).
///
/// Menyimpan bulan yang ditampilkan dan tanggal terpilih, lalu menyusun grid
/// (termasuk titik hari yang punya item) dan agenda tanggal terpilih dari
/// `watchAllTasks()` + `watchRecurrences()`.
///
/// Item berulang TIDAK disalin ke database: kemunculannya dihitung hanya untuk
/// jendela grid yang terlihat (lihat [CalendarAgenda]).
class CalendarCubit extends Cubit<CalendarState> {
  final TaskRepository _taskRepository;

  /// Cermin tanggal terpilih untuk panel "Buat Baru" (lihat [CalendarSelection]).
  final CalendarSelection _selection;

  /// Sumber waktu; bisa diganti pada pengujian.
  final DateTime Function() _now;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<TaskRecurrence>>? _recurrencesSub;

  List<Task> _tasks = const [];
  List<TaskRecurrence> _recurrences = const [];

  /// Error per stream: status tetap error selama salah satu stream gagal, dan
  /// pulih setelah [retry].
  bool _tasksFailed = false;
  bool _recurrencesFailed = false;
  String? _errorMessage;

  CalendarCubit({
    required TaskRepository taskRepository,
    required CalendarSelection selection,
    DateTime Function()? now,
  })  : _taskRepository = taskRepository,
        _selection = selection,
        _now = now ?? DateTime.now,
        super(_initialState(now ?? DateTime.now));

  static CalendarState _initialState(DateTime Function() now) {
    final today = dateOnly(now());
    return CalendarState(
      visibleMonth: CalendarGrid.firstOfMonth(today),
      selectedDate: today,
      today: today,
    );
  }

  /// Berlangganan data item dan aturan pengulangan.
  void start() {
    // Tanggal terpilih sudah diketahui sejak awal (bukan dari stream data),
    // jadi panel "Buat Baru" sudah dapat memakainya walau agenda masih dimuat.
    _selection.select(state.selectedDate);

    unawaited(_tasksSub?.cancel());
    unawaited(_recurrencesSub?.cancel());

    _tasksSub = _taskRepository.watchAllTasks().listen(
      (tasks) {
        _tasksFailed = false;
        _tasks = tasks;
        _recompute();
      },
      onError: (Object error) {
        _tasksFailed = true;
        _errorMessage = '$error';
        _recompute();
      },
    );
    _recurrencesSub = _taskRepository.watchRecurrences().listen(
      (rules) {
        _recurrencesFailed = false;
        _recurrences = rules;
        _recompute();
      },
      onError: (Object error) {
        _recurrencesFailed = true;
        _errorMessage = '$error';
        _recompute();
      },
    );
  }

  /// Pindah ke bulan sebelumnya. Tanggal terpilih ikut bergeser ke bulan itu
  /// dengan hari yang sama, dipangkas ke hari terakhir bila bulan tujuan lebih
  /// pendek (mis. 31 Jan -> 28/29 Feb).
  void previousMonth() => _moveMonth(-1);

  /// Pindah ke bulan berikutnya (aturan pemangkasan sama seperti
  /// [previousMonth]).
  void nextMonth() => _moveMonth(1);

  void _moveMonth(int delta) {
    final month = DateTime(
      state.visibleMonth.year,
      state.visibleMonth.month + delta,
      1,
    );
    _recompute(visibleMonth: month, selectedDate: _dayInMonth(month));
  }

  /// Memilih tanggal. Bila tanggal berada di bulan lain, grid ikut pindah.
  void selectDate(DateTime date) {
    final day = dateOnly(date);
    _recompute(
      visibleMonth: CalendarGrid.firstOfMonth(day),
      selectedDate: day,
    );
  }

  /// Memuat ulang setelah error.
  void retry() {
    _tasksFailed = false;
    _recurrencesFailed = false;
    emit(state.copyWith(status: CalendarStatus.loading, clearError: true));
    start();
  }

  /// Memulihkan item yang baru dihapus dari Kalender (aksi "Urungkan").
  ///
  /// Id berasal dari `softDeleteTask` sehingga induk dan sub-tugasnya ikut
  /// pulih; agenda dan titik warna menyusul dari stream yang sama.
  Future<void> restore(List<String> ids) => _taskRepository.restoreTasks(ids);

  /// Membuka atau menutup daftar sub-tugas satu kartu agenda.
  ///
  /// Keadaan hanya untuk sesi layar ini (disimpan di [CalendarState], bukan di
  /// database) dan tetap saat ganti tanggal atau bulan. Bawaan: tertutup.
  void toggleSubtasks(String taskId) {
    final expanded = {...state.expandedCardIds};
    if (!expanded.remove(taskId)) {
      expanded.add(taskId);
    }
    emit(state.copyWith(expandedCardIds: expanded));
  }

  /// Hari yang sama dengan [state.selectedDate] pada bulan [month], dipangkas
  /// ke hari terakhir [month] bila perlu.
  DateTime _dayInMonth(DateTime month) {
    final lastDay = CalendarGrid.lastOfMonth(month).day;
    final day = state.selectedDate.day > lastDay
        ? lastDay
        : state.selectedDate.day;
    return DateTime(month.year, month.month, day);
  }

  void _recompute({DateTime? visibleMonth, DateTime? selectedDate}) {
    final month = visibleMonth ?? state.visibleMonth;
    final selected = selectedDate ?? state.selectedDate;
    final failed = _tasksFailed || _recurrencesFailed;

    _selection.select(selected);

    emit(
      state.copyWith(
        status: failed ? CalendarStatus.error : CalendarStatus.loaded,
        visibleMonth: month,
        selectedDate: selected,
        today: dateOnly(_now()),
        daysWithItems: CalendarAgenda.daysWithItems(
          tasks: _tasks,
          recurrences: _recurrences,
          from: CalendarGrid.gridStart(month),
          to: CalendarGrid.gridEnd(month),
        ),
        agenda: CalendarAgenda.entriesOnDay(
          tasks: _tasks,
          recurrences: _recurrences,
          day: selected,
        ),
        errorMessage: failed ? _errorMessage : null,
        clearError: !failed,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _tasksSub?.cancel();
    await _recurrencesSub?.cancel();
    return super.close();
  }
}
