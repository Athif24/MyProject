import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
import 'package:sync_daily/features/calendar/presentation/widgets/calendar_item_tile.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Tes teks jam entri agenda Kalender, terutama acara lintas hari (hari
/// pertama, hari tengah, hari terakhir).
void main() {
  final ts = DateTime.utc(2026, 1, 1);

  final task = Task(
    id: 't1',
    title: 'Rapat luar kota',
    type: TaskType.event,
    startAt: DateTime(2026, 10, 14, 9),
    endAt: DateTime(2026, 10, 16, 17),
    createdAt: ts,
    updatedAt: ts,
  );

  CalendarEntry entry(CalendarTimeKind kind, [DateTime? time]) => CalendarEntry(
        task: task,
        date: DateTime(2026, 10, 14),
        timeKind: kind,
        time: time,
      );

  test('hari pertama acara lintas hari memakai "Mulai"', () {
    expect(
      calendarTimeLabel(entry(CalendarTimeKind.startsAt, DateTime(2026, 10, 14, 9))),
      'Mulai 09.00',
    );
  });

  test('hari tengah acara lintas hari memakai "Sepanjang hari"', () {
    expect(
      calendarTimeLabel(entry(CalendarTimeKind.allDay)),
      AppStrings.allDay,
    );
    expect(calendarTimeLabel(entry(CalendarTimeKind.allDay)), 'Sepanjang hari');
  });

  test('hari terakhir acara lintas hari memakai "Sampai"', () {
    expect(
      calendarTimeLabel(entry(CalendarTimeKind.endsAt, DateTime(2026, 10, 16, 17))),
      'Sampai 17.00',
    );
  });

  test('item berjam pada satu hari memakai jam saja', () {
    expect(
      calendarTimeLabel(entry(CalendarTimeKind.clock, DateTime(2026, 10, 14, 13, 5))),
      '13.05',
    );
  });

  test('jam nol menit tetap dua angka', () {
    expect(
      calendarTimeLabel(entry(CalendarTimeKind.clock, DateTime(2026, 10, 14, 7))),
      '07.00',
    );
  });

  test('teks jam dibangun dari AppStrings, bukan ditulis di widget', () {
    expect(
      AppStrings.startsAtTime('09.00'),
      calendarTimeLabel(entry(CalendarTimeKind.startsAt, DateTime(2026, 10, 14, 9))),
    );
    expect(
      AppStrings.endsAtTime('17.00'),
      calendarTimeLabel(entry(CalendarTimeKind.endsAt, DateTime(2026, 10, 16, 17))),
    );
  });

  test('entry berjam tanpa nilai jam menghasilkan label kosong', () {
    expect(calendarTimeLabel(entry(CalendarTimeKind.clock)), isNull);
    expect(calendarTimeLabel(entry(CalendarTimeKind.startsAt)), isNull);
    expect(calendarTimeLabel(entry(CalendarTimeKind.endsAt)), isNull);
  });
}
