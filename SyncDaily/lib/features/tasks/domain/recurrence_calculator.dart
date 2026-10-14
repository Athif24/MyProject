import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';

/// Menghitung kemunculan (occurrence) dari sebuah aturan pengulangan pada
/// rentang tanggal tertentu.
///
/// Untuk F2 hanya perhitungan kemunculan yang dibuat. Penandaan selesai per
/// kemunculan belum dikerjakan (TODO F4).
class RecurrenceCalculator {
  const RecurrenceCalculator._();

  /// Mengembalikan daftar waktu kemunculan yang jatuh di dalam `[from, to]`
  /// (inklusif), dihitung maju dari [anchor] (kemunculan pertama).
  static List<DateTime> occurrencesInRange({
    required TaskRecurrence rule,
    required DateTime anchor,
    required DateTime from,
    required DateTime to,
  }) {
    final result = <DateTime>[];
    if (to.isBefore(from)) {
      return result;
    }

    final until = rule.untilAt;
    var emitted = 0;
    final limit = rule.count;

    bool withinLimits(DateTime candidate) {
      if (until != null && candidate.isAfter(until)) {
        return false;
      }
      if (limit != null && emitted >= limit) {
        return false;
      }
      return true;
    }

    void collect(DateTime candidate) {
      emitted++;
      if (!candidate.isBefore(from) && !candidate.isAfter(to)) {
        result.add(candidate);
      }
    }

    if (rule.frequency == RecurrenceFrequency.weekly &&
        (rule.byWeekdays?.isNotEmpty ?? false)) {
      final weekStart = _startOfWeek(anchor);
      final selected = rule.byWeekdays!;
      var weekOffset = 0;
      outer:
      while (weekOffset < 5000) {
        final base = weekStart.add(
          Duration(days: 7 * rule.intervalValue * weekOffset),
        );
        for (final day in Weekday.values) {
          if (!selected.contains(day)) {
            continue;
          }
          final candidate = DateTime(
            base.year,
            base.month,
            base.day + day.index,
            anchor.hour,
            anchor.minute,
          );
          if (candidate.isBefore(anchor)) {
            continue;
          }
          if (!withinLimits(candidate)) {
            break outer;
          }
          collect(candidate);
          if (candidate.isAfter(to)) {
            break outer;
          }
        }
        weekOffset++;
      }
      return result;
    }

    for (var index = 0; index < 100000; index++) {
      final candidate = _nthOccurrence(rule, anchor, index);
      if (!withinLimits(candidate)) {
        break;
      }
      collect(candidate);
      if (candidate.isAfter(to)) {
        break;
      }
    }
    return result;
  }

  static DateTime _nthOccurrence(
    TaskRecurrence rule,
    DateTime anchor,
    int index,
  ) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return anchor.add(Duration(days: index * rule.intervalValue));
      case RecurrenceFrequency.weekly:
        return anchor.add(Duration(days: 7 * index * rule.intervalValue));
      case RecurrenceFrequency.monthly:
        return _addMonths(
          anchor,
          index * rule.intervalValue,
          rule.byMonthDay,
        );
      case RecurrenceFrequency.yearly:
        return _addYears(anchor, index * rule.intervalValue);
    }
  }

  static DateTime _addMonths(DateTime anchor, int months, int? day) {
    final total = anchor.month - 1 + months;
    final year = anchor.year + total ~/ 12;
    final month = total % 12 + 1;
    final targetDay = day ?? anchor.day;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      targetDay > lastDay ? lastDay : targetDay,
      anchor.hour,
      anchor.minute,
    );
  }

  static DateTime _addYears(DateTime anchor, int years) {
    final year = anchor.year + years;
    final lastDay = DateTime(year, anchor.month + 1, 0).day;
    return DateTime(
      year,
      anchor.month,
      anchor.day > lastDay ? lastDay : anchor.day,
      anchor.hour,
      anchor.minute,
    );
  }

  /// Senin sebagai awal minggu.
  static DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: value.weekday - 1));
  }
}
