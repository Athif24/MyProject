import 'package:sync_daily/features/calendar/domain/calendar_grid.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/recurrence_calculator.dart';

/// Cara menampilkan jam sebuah entri Kalender.
enum CalendarTimeKind {
  /// Tanpa jam: item seharian, atau hari tengah acara lintas hari.
  allDay,

  /// Jam tunggal: item yang jatuh pada satu hari saja.
  clock,

  /// Hari pertama acara lintas hari. Contoh: `Mulai 09.00`.
  startsAt,

  /// Hari terakhir acara lintas hari. Contoh: `Sampai 17.00`.
  endsAt,
}

/// Satu baris agenda Kalender pada satu hari.
class CalendarEntry {
  final Task task;

  /// Hari tempat entri muncul (tanpa jam, waktu lokal).
  final DateTime date;
  final CalendarTimeKind timeKind;

  /// Jam acuan untuk [CalendarTimeKind.clock], [CalendarTimeKind.startsAt],
  /// dan [CalendarTimeKind.endsAt].
  final DateTime? time;

  const CalendarEntry({
    required this.task,
    required this.date,
    required this.timeKind,
    this.time,
  });
}

/// Menyusun agenda Kalender dari daftar item dan aturan pengulangan.
///
/// Aturan tanggal mengikuti `TaskDateUtils.referenceDate`:
/// - item seharian memakai tanggal kalender UTC yang tersimpan apa adanya;
/// - item berjam dibaca lewat waktu lokal perangkat (`toLocal()`).
///
/// Kemunculan item berulang DIHITUNG, bukan disalin ke database, dan dibatasi
/// jendela `[from, to]` supaya cepat.
class CalendarAgenda {
  const CalendarAgenda._();

  /// Tanggal yang punya item dalam `[from, to]` beserta tipe itemnya (dipakai
  /// titik warna di grid).
  static Map<DateTime, Set<TaskType>> daysWithItems({
    required List<Task> tasks,
    required List<TaskRecurrence> recurrences,
    required DateTime from,
    required DateTime to,
  }) {
    final result = <DateTime, Set<TaskType>>{};
    for (final entry in entriesInRange(
      tasks: tasks,
      recurrences: recurrences,
      from: from,
      to: to,
    )) {
      result.putIfAbsent(entry.date, () => <TaskType>{}).add(entry.task.type);
    }
    return result;
  }

  /// Entri agenda pada satu hari, terurut: item tanpa jam lebih dahulu, lalu
  /// menurut jam, lalu judul.
  static List<CalendarEntry> entriesOnDay({
    required List<Task> tasks,
    required List<TaskRecurrence> recurrences,
    required DateTime day,
  }) {
    final date = dateOnly(day);
    return entriesInRange(
      tasks: tasks,
      recurrences: recurrences,
      from: date,
      to: date,
    );
  }

  /// Seluruh entri dalam `[from, to]`, termasuk hari-hari acara lintas hari dan
  /// kemunculan item berulang.
  static List<CalendarEntry> entriesInRange({
    required List<Task> tasks,
    required List<TaskRecurrence> recurrences,
    required DateTime from,
    required DateTime to,
  }) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    if (end.isBefore(start)) {
      return const [];
    }

    final rules = {for (final rule in recurrences) rule.taskId: rule};
    final entries = <CalendarEntry>[];
    final seen = <String>{};

    for (final task in tasks) {
      final anchor = _anchor(task);
      if (anchor == null) {
        continue;
      }
      final span = _span(task);
      final spanDays = span == null ? 0 : dayCount(span.start, span.end);
      final anchorMoment = anchor.clock ?? anchor.date;

      final rule = rules[task.id];
      final occurrences = rule == null
          ? [anchorMoment]
          : RecurrenceCalculator.occurrencesInRange(
              rule: rule,
              anchor: anchorMoment,
              // Acara lintas hari bisa mulai sebelum jendela.
              from: addDays(start, -spanDays),
              // Satu hari setelah hari terakhir, karena kemunculan berjam jam
              // bawaannya lebih besar dari tengah malam batas jendela.
              to: addDays(end, 1),
            );

      for (final occurrence in occurrences) {
        final firstDay = dateOnly(occurrence);
        for (var offset = 0; offset <= spanDays; offset++) {
          final date = addDays(firstDay, offset);
          if (date.isBefore(start) || date.isAfter(end)) {
            continue;
          }
          if (!seen.add('${task.id}@${date.year}-${date.month}-${date.day}')) {
            continue;
          }
          final view = _presentation(task, span, offset, spanDays);
          entries.add(CalendarEntry(
            task: task,
            date: date,
            timeKind: view.kind,
            time: view.time,
          ));
        }
      }
    }

    return _sorted(entries);
  }

  /// Titik acuan sebuah item: tanggal kalender + jam lokal (null bila seharian
  /// atau tidak punya tanggal).
  static ({DateTime date, DateTime? clock})? _anchor(Task task) {
    final raw = task.dueAt ?? task.startAt ?? task.endAt;
    if (raw == null) {
      return null;
    }
    if (task.isAllDay) {
      return (date: utcDateOnly(raw), clock: null);
    }
    final local = raw.toLocal();
    return (
      date: dateOnly(local),
      clock: DateTime(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
      ),
    );
  }

  /// Rentang hari acara lintas hari (null bila bukan lintas hari).
  static ({DateTime start, DateTime end})? _span(Task task) {
    if (task.type != TaskType.event) {
      return null;
    }
    final startRaw = task.startAt;
    final endRaw = task.endAt;
    if (startRaw == null || endRaw == null) {
      return null;
    }
    final start = task.isAllDay ? utcDateOnly(startRaw) : localDateOnly(startRaw);
    final end = task.isAllDay ? utcDateOnly(endRaw) : localDateOnly(endRaw);
    if (!end.isAfter(start)) {
      return null;
    }
    return (start: start, end: end);
  }

  static ({CalendarTimeKind kind, DateTime? time}) _presentation(
    Task task,
    ({DateTime start, DateTime end})? span,
    int offset,
    int spanDays,
  ) {
    final clock = _clock(task);
    if (span == null) {
      if (task.isAllDay || clock == null) {
        return (kind: CalendarTimeKind.allDay, time: null);
      }
      return (kind: CalendarTimeKind.clock, time: clock);
    }
    if (offset == 0) {
      if (task.isAllDay || clock == null) {
        return (kind: CalendarTimeKind.allDay, time: null);
      }
      return (kind: CalendarTimeKind.startsAt, time: clock);
    }
    if (offset == spanDays) {
      final endClock = _endClock(task);
      if (task.isAllDay || endClock == null) {
        return (kind: CalendarTimeKind.allDay, time: null);
      }
      return (kind: CalendarTimeKind.endsAt, time: endClock);
    }
    return (kind: CalendarTimeKind.allDay, time: null);
  }

  static DateTime? _clock(Task task) {
    if (task.isAllDay) {
      return null;
    }
    final raw = task.dueAt ?? task.startAt ?? task.endAt;
    if (raw == null) {
      return null;
    }
    final local = raw.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }

  static DateTime? _endClock(Task task) {
    if (task.isAllDay) {
      return null;
    }
    final raw = task.endAt;
    if (raw == null) {
      return null;
    }
    final local = raw.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }

  /// Urutan agenda: hari lebih dulu (agar acara lintas hari tetap kronologis),
  /// lalu item seharian, lalu menurut jam, judul, dan id.
  static List<CalendarEntry> _sorted(List<CalendarEntry> entries) {
    final list = [...entries];
    list.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) {
        return byDate;
      }
      final aAllDay = a.timeKind == CalendarTimeKind.allDay;
      final bAllDay = b.timeKind == CalendarTimeKind.allDay;
      if (aAllDay != bAllDay) {
        return aAllDay ? -1 : 1;
      }
      final aTime = a.time;
      final bTime = b.time;
      if (aTime != null && bTime != null) {
        final byTime = aTime.compareTo(bTime);
        if (byTime != 0) {
          return byTime;
        }
      }
      final byTitle = a.task.title.compareTo(b.task.title);
      if (byTitle != 0) {
        return byTitle;
      }
      final byId = a.task.id.compareTo(b.task.id);
      if (byId != 0) {
        return byId;
      }
      return 0;
    });
    return list;
  }
}
