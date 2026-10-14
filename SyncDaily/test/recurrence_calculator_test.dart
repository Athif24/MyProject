import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/recurrence_calculator.dart';

void main() {
  TaskRecurrence rule({
    required RecurrenceFrequency frequency,
    int interval = 1,
    Set<Weekday>? byWeekdays,
    int? byMonthDay,
    DateTime? untilAt,
    int? count,
  }) {
    final ts = DateTime.utc(2026, 1, 1);
    return TaskRecurrence(
      taskId: 't',
      frequency: frequency,
      intervalValue: interval,
      byWeekdays: byWeekdays,
      byMonthDay: byMonthDay,
      untilAt: untilAt,
      count: count,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  test('harian dengan interval', () {
    final result = RecurrenceCalculator.occurrencesInRange(
      rule: rule(frequency: RecurrenceFrequency.daily, interval: 2),
      anchor: DateTime(2026, 10, 1),
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 7),
    );
    expect(
      result,
      [
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 7),
      ],
    );
  });

  test('mingguan pada hari tertentu', () {
    final result = RecurrenceCalculator.occurrencesInRange(
      rule: rule(
        frequency: RecurrenceFrequency.weekly,
        byWeekdays: const {Weekday.monday, Weekday.friday},
      ),
      // 1 Okt 2026 adalah Kamis.
      anchor: DateTime(2026, 10, 1),
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 12),
    );
    expect(
      result,
      [
        DateTime(2026, 10, 2), // Jumat
        DateTime(2026, 10, 5), // Senin
        DateTime(2026, 10, 9), // Jumat
        DateTime(2026, 10, 12), // Senin
      ],
    );
  });

  test('bulanan memakai hari tertentu', () {
    final result = RecurrenceCalculator.occurrencesInRange(
      rule: rule(frequency: RecurrenceFrequency.monthly, byMonthDay: 15),
      anchor: DateTime(2026, 1, 15),
      from: DateTime(2026, 1, 1),
      to: DateTime(2026, 4, 30),
    );
    expect(
      result,
      [
        DateTime(2026, 1, 15),
        DateTime(2026, 2, 15),
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 15),
      ],
    );
  });

  test('menghormati count', () {
    final result = RecurrenceCalculator.occurrencesInRange(
      rule: rule(frequency: RecurrenceFrequency.daily, count: 3),
      anchor: DateTime(2026, 10, 1),
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 31),
    );
    expect(result.length, 3);
    expect(result.last, DateTime(2026, 10, 3));
  });

  test('menghormati untilAt', () {
    final result = RecurrenceCalculator.occurrencesInRange(
      rule: rule(
        frequency: RecurrenceFrequency.daily,
        untilAt: DateTime(2026, 10, 3),
      ),
      anchor: DateTime(2026, 10, 1),
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 31),
    );
    expect(result, [
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 2),
      DateTime(2026, 10, 3),
    ]);
  });
}
