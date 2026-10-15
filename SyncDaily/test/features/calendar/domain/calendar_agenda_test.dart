import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';

/// Tes penyusunan agenda Kalender: aturan tanggal (seharian vs berjam), acara
/// lintas hari, item berulang, dan batas jendela.
void main() {
  final ts = DateTime.utc(2026, 1, 1);

  Task task({
    String id = 't1',
    TaskType type = TaskType.task,
    String title = 'Item',
    DateTime? startAt,
    DateTime? endAt,
    DateTime? dueAt,
    bool isAllDay = false,
    TaskStatus status = TaskStatus.todo,
  }) {
    return Task(
      id: id,
      title: title,
      type: type,
      status: status,
      startAt: startAt,
      endAt: endAt,
      dueAt: dueAt,
      isAllDay: isAllDay,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  TaskRecurrence rule(
    String taskId,
    RecurrenceFrequency frequency, {
    int intervalValue = 1,
  }) {
    return TaskRecurrence(
      taskId: taskId,
      frequency: frequency,
      intervalValue: intervalValue,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  Map<DateTime, Set<TaskType>> days({
    required List<Task> tasks,
    List<TaskRecurrence> recurrences = const [],
    DateTime? from,
    DateTime? to,
  }) {
    return CalendarAgenda.daysWithItems(
      tasks: tasks,
      recurrences: recurrences,
      from: from ?? DateTime(2026, 10, 12),
      to: to ?? DateTime(2026, 10, 18),
    );
  }

  group('aturan tanggal', () {
    test('item seharian memakai tanggal UTC yang tersimpan (WIB)', () {
      // Jendela seperti perangkat WIB: batas lokal tengah malam.
      final allDay = task(
        isAllDay: true,
        dueAt: DateTime.utc(2026, 10, 14),
      );

      expect(days(tasks: [allDay]).keys, contains(DateTime(2026, 10, 14)));
    });

    test('item seharian tidak bergeser di zona negatif (UTC-8)', () {
      // Batas jendela 12 Okt 00.00 UTC-8 = 12 Okt 08.00 UTC.
      final allDay = task(
        isAllDay: true,
        dueAt: DateTime.utc(2026, 10, 14),
      );

      final result = days(
        tasks: [allDay],
        from: DateTime.utc(2026, 10, 12, 8),
        to: DateTime.utc(2026, 10, 18, 8),
      );

      expect(result.keys, contains(DateTime(2026, 10, 14)));
      expect(result.keys, hasLength(1));
    });

    test('item seharian yang tersimpan 23.45 UTC tetap di tanggal itu', () {
      final allDay = task(
        isAllDay: true,
        dueAt: DateTime.utc(2026, 10, 14, 23, 45),
      );

      expect(days(tasks: [allDay]).keys, contains(DateTime(2026, 10, 14)));
    });

    test('item berjam memakai tanggal lokal perangkat', () {
      final timed = task(dueAt: DateTime(2026, 10, 14, 23, 30));

      final result = days(tasks: [timed]);

      expect(result.keys, contains(DateTime(2026, 10, 14)));
      expect(result[DateTime(2026, 10, 14)], {TaskType.task});
    });

    test('item tanpa tanggal tidak muncul', () {
      expect(days(tasks: [task()]), isEmpty);
    });

    test('item berjam pada hari terakhir jendela tetap muncul', () {
      final timed = task(dueAt: DateTime(2026, 10, 18, 20));

      expect(days(tasks: [timed]).keys, contains(DateTime(2026, 10, 18)));
    });
  });

  group('acara lintas hari', () {
    test('acara lintas hari muncul setiap hari dengan label yang berbeda', () {
      final event = task(
        id: 'e1',
        type: TaskType.event,
        title: 'Rapat luar kota',
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 16, 17),
      );

      final entries = CalendarAgenda.entriesInRange(
        tasks: [event],
        recurrences: const [],
        from: DateTime(2026, 10, 12),
        to: DateTime(2026, 10, 18),
      );

      expect(entries, hasLength(3));
      expect(entries[0].date, DateTime(2026, 10, 14));
      expect(entries[0].timeKind, CalendarTimeKind.startsAt);
      expect(entries[0].time, DateTime(2026, 10, 14, 9));
      expect(entries[1].date, DateTime(2026, 10, 15));
      expect(entries[1].timeKind, CalendarTimeKind.allDay);
      expect(entries[2].date, DateTime(2026, 10, 16));
      expect(entries[2].timeKind, CalendarTimeKind.endsAt);
      expect(entries[2].time, DateTime(2026, 10, 16, 17));
    });

    test('titik grid muncul di semua hari acara lintas hari', () {
      final event = task(
        id: 'e1',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 16, 17),
      );

      final result = days(tasks: [event]);

      expect(result.keys, contains(DateTime(2026, 10, 14)));
      expect(result.keys, contains(DateTime(2026, 10, 15)));
      expect(result.keys, contains(DateTime(2026, 10, 16)));
      expect(result.keys, hasLength(3));
      expect(result[DateTime(2026, 10, 15)], {TaskType.event});
    });

    test('acara seharian lintas hari: semua hari Sepanjang hari', () {
      final event = task(
        id: 'e1',
        type: TaskType.event,
        startAt: DateTime.utc(2026, 10, 14),
        endAt: DateTime.utc(2026, 10, 16),
        isAllDay: true,
      );

      final entries = CalendarAgenda.entriesInRange(
        tasks: [event],
        recurrences: const [],
        from: DateTime(2026, 10, 12),
        to: DateTime(2026, 10, 18),
      );

      expect(entries, hasLength(3));
      for (final entry in entries) {
        expect(entry.timeKind, CalendarTimeKind.allDay);
        expect(entry.time, isNull);
      }
      expect(
        entries.map((entry) => entry.date),
        [DateTime(2026, 10, 14), DateTime(2026, 10, 15), DateTime(2026, 10, 16)],
      );
    });

    test('acara dua hari: hari pertama Mulai, hari terakhir Sampai', () {
      final event = task(
        id: 'e1',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 15, 17),
      );

      final entries = CalendarAgenda.entriesOnDay(
        tasks: [event],
        recurrences: const [],
        day: DateTime(2026, 10, 14),
      );
      expect(entries.single.timeKind, CalendarTimeKind.startsAt);

      final last = CalendarAgenda.entriesOnDay(
        tasks: [event],
        recurrences: const [],
        day: DateTime(2026, 10, 15),
      );
      expect(last.single.timeKind, CalendarTimeKind.endsAt);
    });

    test('acara satu hari berjam memakai jam tunggal', () {
      final event = task(
        id: 'e1',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 14, 11),
      );

      final entries = CalendarAgenda.entriesOnDay(
        tasks: [event],
        recurrences: const [],
        day: DateTime(2026, 10, 14),
      );

      expect(entries.single.timeKind, CalendarTimeKind.clock);
      expect(entries.single.time, DateTime(2026, 10, 14, 9));
    });
  });

  group('item berulang', () {
    test('harian muncul di setiap hari sejak tanggal acuan', () {
      final daily = task(id: 'r1', title: 'Minum obat', dueAt: DateTime(2026, 10, 14));
      final result = days(
        tasks: [daily],
        recurrences: [rule('r1', RecurrenceFrequency.daily)],
      );

      expect(
        result.keys.toList()..sort(),
        [
          DateTime(2026, 10, 14),
          DateTime(2026, 10, 15),
          DateTime(2026, 10, 16),
          DateTime(2026, 10, 17),
          DateTime(2026, 10, 18),
        ],
      );
    });

    test('harian tidak muncul sebelum tanggal acuan', () {
      final daily = task(id: 'r1', dueAt: DateTime(2026, 10, 14));
      final result = days(
        tasks: [daily],
        recurrences: [rule('r1', RecurrenceFrequency.daily)],
      );

      expect(result.containsKey(DateTime(2026, 10, 13)), isFalse);
    });

    test('kemunculan berjam pada hari terakhir jendela tetap muncul', () {
      final daily = task(id: 'r1', dueAt: DateTime(2026, 10, 14, 20));
      final result = days(
        tasks: [daily],
        recurrences: [rule('r1', RecurrenceFrequency.daily)],
      );

      expect(result.keys, contains(DateTime(2026, 10, 18)));
      expect(
        CalendarAgenda.entriesOnDay(
          tasks: [daily],
          recurrences: [rule('r1', RecurrenceFrequency.daily)],
          day: DateTime(2026, 10, 18),
        ),
        hasLength(1),
      );
    });

    test('mingguan muncul setiap tujuh hari', () {
      final weekly = task(id: 'r1', dueAt: DateTime(2026, 10, 14));
      final result = days(
        tasks: [weekly],
        recurrences: [rule('r1', RecurrenceFrequency.weekly)],
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
      );

      expect(
        result.keys.toList()..sort(),
        [
          DateTime(2026, 10, 14),
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 28),
        ],
      );
    });

    test('bulanan tanggal 31 dipangkas ke hari terakhir bulan pendek', () {
      final monthly = task(id: 'r1', dueAt: DateTime(2026, 1, 31));
      final result = days(
        tasks: [monthly],
        recurrences: [rule('r1', RecurrenceFrequency.monthly)],
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 3, 31),
      );

      expect(
        result.keys.toList()..sort(),
        [DateTime(2026, 2, 28), DateTime(2026, 3, 31)],
      );
    });

    test('bulanan tanggal 31 memakai 29 Februari pada tahun kabisat', () {
      final monthly = task(id: 'r1', dueAt: DateTime(2024, 1, 31));
      final result = days(
        tasks: [monthly],
        recurrences: [rule('r1', RecurrenceFrequency.monthly)],
        from: DateTime(2024, 2, 1),
        to: DateTime(2024, 2, 29),
      );

      expect(result.keys, [DateTime(2024, 2, 29)]);
    });

    test('kemunculan berulang TIDAK menambah baris database', () {
      // Perluasan hanya di memori: jumlah entri tidak mengubah daftar aturan.
      final daily = task(id: 'r1', dueAt: DateTime(2026, 10, 14));
      final rules = [rule('r1', RecurrenceFrequency.daily)];

      expect(rules, hasLength(1));
      expect(
        days(tasks: [daily], recurrences: rules).keys,
        hasLength(5),
      );
      expect(rules, hasLength(1));
    });

    test('acara lintas hari berulang tidak menggandakan entri per hari', () {
      final event = task(
        id: 'e1',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 15, 17),
      );

      final entries = CalendarAgenda.entriesInRange(
        tasks: [event],
        recurrences: [rule('e1', RecurrenceFrequency.daily)],
        from: DateTime(2026, 10, 14),
        to: DateTime(2026, 10, 18),
      );

      expect(entries, hasLength(5));
      expect(
        entries.map((entry) => entry.date).toSet(),
        hasLength(5),
      );
    });
  });

  group('daftar agenda satu hari', () {
    test('item selesai tetap muncul', () {
      final done = task(
        id: 'd1',
        title: 'Sudah selesai',
        dueAt: DateTime(2026, 10, 14, 8),
        status: TaskStatus.done,
      );

      final entries = CalendarAgenda.entriesOnDay(
        tasks: [done],
        recurrences: const [],
        day: DateTime(2026, 10, 14),
      );

      expect(entries.single.task.status, TaskStatus.done);
    });

    test('urutan: item seharian dulu, lalu menurut jam', () {
      final timedLate = task(
        id: 'b',
        title: 'Siang',
        dueAt: DateTime(2026, 10, 14, 13),
      );
      final allDay = task(
        id: 'a',
        title: 'Seharian',
        isAllDay: true,
        dueAt: DateTime.utc(2026, 10, 14),
      );
      final timedEarly = task(
        id: 'c',
        title: 'Pagi',
        dueAt: DateTime(2026, 10, 14, 7),
      );

      final entries = CalendarAgenda.entriesOnDay(
        tasks: [timedLate, allDay, timedEarly],
        recurrences: const [],
        day: DateTime(2026, 10, 14),
      );

      expect(
        entries.map((entry) => entry.task.title),
        ['Seharian', 'Pagi', 'Siang'],
      );
    });

    test('tanggal lain tidak ikut tampil', () {
      final today = task(dueAt: DateTime(2026, 10, 14, 8));
      final other = task(id: 'o', dueAt: DateTime(2026, 10, 15, 8));

      final entries = CalendarAgenda.entriesOnDay(
        tasks: [today, other],
        recurrences: const [],
        day: DateTime(2026, 10, 14),
      );

      expect(entries.single.task.id, 't1');
    });
  });
}
