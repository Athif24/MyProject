import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';

void main() {
  Task task({
    DateTime? startAt,
    DateTime? dueAt,
    bool isAllDay = false,
  }) {
    final ts = DateTime.utc(2026, 1, 1);
    return Task(
      id: 't',
      title: 'Tugas',
      type: TaskType.task,
      startAt: startAt,
      dueAt: dueAt,
      isAllDay: isAllDay,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  TaskReminder reminder(int offset) {
    final ts = DateTime.utc(2026, 1, 1);
    return TaskReminder(
      id: 'r',
      taskId: 't',
      offsetMinutes: offset,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  test('titik acuan pengingat memakai startAt bila ada', () {
    final t = task(
      startAt: DateTime.utc(2026, 10, 1, 9),
      dueAt: DateTime.utc(2026, 10, 1, 17),
    );
    expect(
      TaskDateUtils.reminderTimeFor(t, reminder(30)),
      DateTime.utc(2026, 10, 1, 8, 30),
    );
  });

  test('titik acuan pengingat memakai dueAt bila startAt kosong', () {
    final t = task(dueAt: DateTime.utc(2026, 10, 1, 17));
    expect(
      TaskDateUtils.reminderTimeFor(t, reminder(60)),
      DateTime.utc(2026, 10, 1, 16),
    );
  });

  test('offset 0 untuk reminder memakai waktu tugas itu sendiri', () {
    final t = task(startAt: DateTime.utc(2026, 10, 1, 7));
    expect(
      TaskDateUtils.reminderTimeFor(t, reminder(0)),
      DateTime.utc(2026, 10, 1, 7),
    );
  });

  test('item all-day tidak bergeser sehari', () {
    final t = task(isAllDay: true, dueAt: DateTime.utc(2026, 10, 14));
    expect(TaskDateUtils.isOnDay(t, DateTime(2026, 10, 14)), isTrue);
    expect(TaskDateUtils.isOnDay(t, DateTime(2026, 10, 15)), isFalse);
  });

  group('perbandingan periode sebagai tanggal kalender', () {
    test('UTC-8: all-day hari pertama dan terakhir periode tetap ikut', () {
      // Perangkat UTC-8: tengah malam 12 Okt lokal = 12 Okt 08.00 UTC.
      // Perbandingan instan waktu akan membuang item all-day 12 Okt di zona
      // negatif (UTC tengah malam dianggap sebelum batas lokal).
      final start = DateTime.utc(2026, 10, 12, 8);
      final end = DateTime.utc(2026, 10, 19, 8);

      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 12), start, end),
        isTrue,
      );
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 11), start, end),
        isFalse,
      );
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 19), start, end),
        isTrue,
      );
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 20), start, end),
        isFalse,
      );
    });

    test('WIB (UTC+7): all-day hari pertama dan terakhir periode tetap ikut',
        () {
      // Batas periode perangkat WIB dibuat dari komponen tanggal lokal; epoch
      // mesin uji tidak berpengaruh karena perbandingan hanya memakai
      // tahun-bulan-hari. Perbandingan instan waktu justru membuang item
      // all-day di hari TERAKHIR periode pada zona positif.
      final start = DateTime(2026, 10, 12);
      final end = DateTime(2026, 10, 19, 23, 59, 59);

      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 12), start, end),
        isTrue,
      );
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 11), start, end),
        isFalse,
      );
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 19), start, end),
        isTrue,
      );
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 20), start, end),
        isFalse,
      );
    });

    test('isInRange memakai tanggal kalender untuk item all-day', () {
      final t = task(isAllDay: true, dueAt: DateTime.utc(2026, 10, 12));

      // UTC-8.
      expect(
        TaskDateUtils.isInRange(
          t,
          DateTime.utc(2026, 10, 12, 8),
          DateTime.utc(2026, 10, 19, 8),
        ),
        isTrue,
      );
      // WIB.
      expect(
        TaskDateUtils.isInRange(
          t,
          DateTime(2026, 10, 12),
          DateTime(2026, 10, 19, 23, 59, 59),
        ),
        isTrue,
      );
      // Di luar rentang.
      expect(
        TaskDateUtils.isInRange(
          t,
          DateTime(2026, 10, 13),
          DateTime(2026, 10, 19, 23, 59, 59),
        ),
        isFalse,
      );
    });

    test('batas null berarti tanpa batas', () {
      expect(
        TaskDateUtils.isWithinPeriod(DateTime.utc(2026, 10, 12), null, null),
        isTrue,
      );
      expect(
        TaskDateUtils.isWithinPeriod(
          DateTime.utc(2026, 10, 12),
          null,
          DateTime(2026, 10, 11),
        ),
        isFalse,
      );
      expect(
        TaskDateUtils.isWithinPeriod(
          DateTime.utc(2026, 10, 12),
          DateTime(2026, 10, 12),
          null,
        ),
        isTrue,
      );
    });
  });

  group('item berjam (bukan all-day)', () {
    // Item berjam memakai tanggal kalender WAKTU LOKAL perangkat
    // (`referenceDate` memanggil `.toLocal()`), sedangkan item all-day memakai
    // tanggal UTC yang tersimpan. Keduanya lalu dibandingkan sebagai tanggal
    // kalender dengan batas periode lokal.
    final start = DateTime(2026, 10, 12);
    final end = DateTime(2026, 10, 19, 23, 59, 59);

    test('acuan all-day = tanggal UTC, item berjam = tanggal lokal', () {
      final allDay = TaskDateUtils.referenceDate(
        task(isAllDay: true, dueAt: DateTime.utc(2026, 10, 12, 23, 45)),
      );
      expect(allDay!.isUtc, isTrue);
      expect(
        [allDay.year, allDay.month, allDay.day],
        [2026, 10, 12],
      );

      final berjam = TaskDateUtils.referenceDate(
        task(dueAt: DateTime(2026, 10, 12, 23, 45)),
      );
      expect(berjam!.isUtc, isFalse);
      expect(
        [berjam.year, berjam.month, berjam.day],
        [2026, 10, 12],
      );
    });

    test('acara 00.30 di hari pertama periode ikut terhitung', () {
      final t = task(dueAt: DateTime(2026, 10, 12, 0, 30));
      expect(TaskDateUtils.isInRange(t, start, end), isTrue);
    });

    test('acara 23.30 di hari terakhir periode ikut terhitung', () {
      final t = task(dueAt: DateTime(2026, 10, 19, 23, 30));
      expect(TaskDateUtils.isInRange(t, start, end), isTrue);
    });

    test('acara 23.30 sehari sebelum periode tidak terhitung', () {
      final t = task(dueAt: DateTime(2026, 10, 11, 23, 30));
      expect(TaskDateUtils.isInRange(t, start, end), isFalse);
    });

    test('padanan UTC-8: batas tengah malam UTC-8 menghitung hari yang sama',
        () {
      // Batas periode sebagai tengah malam UTC-8 (12 Okt 00.00 UTC-8 =
      // 12 Okt 08.00 UTC). Item berjam tetap dibandingkan lewat komponen
      // tanggal lokalnya, sehingga hasilnya sama seperti pada WIB.
      final utc8Start = DateTime.utc(2026, 10, 12, 8);
      final utc8End = DateTime.utc(2026, 10, 19, 8);

      expect(
        TaskDateUtils.isInRange(
          task(dueAt: DateTime(2026, 10, 12, 0, 30)),
          utc8Start,
          utc8End,
        ),
        isTrue,
      );
      expect(
        TaskDateUtils.isInRange(
          task(dueAt: DateTime(2026, 10, 19, 23, 30)),
          utc8Start,
          utc8End,
        ),
        isTrue,
      );
      expect(
        TaskDateUtils.isInRange(
          task(dueAt: DateTime(2026, 10, 11, 23, 30)),
          utc8Start,
          utc8End,
        ),
        isFalse,
      );
    });
  });
}
