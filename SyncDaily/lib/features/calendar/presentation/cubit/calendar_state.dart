import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

enum CalendarStatus { loading, loaded, error }

/// Keadaan layar Kalender (F5).
class CalendarState extends Equatable {
  final CalendarStatus status;

  /// Tanggal 1 bulan yang ditampilkan grid.
  final DateTime visibleMonth;

  /// Tanggal terpilih (tanpa jam, waktu lokal perangkat).
  final DateTime selectedDate;

  /// "Hari ini" menurut jam yang disuntikkan ke cubit.
  final DateTime today;

  /// Hari yang punya item di jendela grid, beserta tipe itemnya (untuk titik
  /// warna). Kuncinya tanggal tanpa jam.
  final Map<DateTime, Set<TaskType>> daysWithItems;

  /// Agenda tanggal terpilih.
  final List<CalendarEntry> agenda;

  /// Id item yang kartunya sedang terbuka (daftar sub-tugasnya tampil).
  ///
  /// Keadaan sesi layar saja: tidak disimpan ke database dan tetap selama layar
  /// Kalender hidup (termasuk saat ganti tanggal atau bulan). Bawaan: semua
  /// kartu tertutup.
  final Set<String> expandedCardIds;

  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.loading,
    required this.visibleMonth,
    required this.selectedDate,
    required this.today,
    this.daysWithItems = const {},
    this.agenda = const [],
    this.expandedCardIds = const <String>{},
    this.errorMessage,
  });

  CalendarState copyWith({
    CalendarStatus? status,
    DateTime? visibleMonth,
    DateTime? selectedDate,
    DateTime? today,
    Map<DateTime, Set<TaskType>>? daysWithItems,
    List<CalendarEntry>? agenda,
    Set<String>? expandedCardIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CalendarState(
      status: status ?? this.status,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      today: today ?? this.today,
      daysWithItems: daysWithItems ?? this.daysWithItems,
      agenda: agenda ?? this.agenda,
      expandedCardIds: expandedCardIds ?? this.expandedCardIds,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  /// True bila [date] adalah "hari ini" menurut jam yang disuntikkan.
  bool isToday(DateTime date) =>
      date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;

  @override
  List<Object?> get props => [
        status,
        visibleMonth,
        selectedDate,
        today,
        daysWithItems,
        agenda,
        expandedCardIds,
        errorMessage,
      ];
}
