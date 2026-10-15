import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/features/calendar/domain/calendar_grid.dart';

/// Tes pembuatan grid bulan Kalender: awal pekan, jumlah baris, dan cakupan
/// hari tiap bulan (28/30/31 hari serta tahun kabisat).
void main() {
  test('awal pekan adalah Senin', () {
    // 1 Okt 2026 jatuh pada Kamis, jadi grid mulai Senin 28 Sep 2026.
    final days = CalendarGrid.days(DateTime(2026, 10, 1));

    expect(days.first.date, DateTime(2026, 9, 28));
    expect(days.first.date.weekday, DateTime.monday);
    expect(days.first.isInMonth, isFalse);
  });

  test('startOfWeek mengembalikan Senin yang sama untuk ketujuh hari', () {
    final monday = DateTime(2026, 10, 12);
    expect(monday.weekday, DateTime.monday);

    for (var offset = 0; offset < 7; offset++) {
      final day = addDays(monday, offset);
      expect(CalendarGrid.startOfWeek(day), monday);
    }
  });

  test('grid selalu 6 baris x 7 kolom dan harinya berurutan', () {
    final weeks = CalendarGrid.weeks(DateTime(2026, 10, 5));

    expect(weeks, hasLength(6));
    for (final week in weeks) {
      expect(week, hasLength(7));
    }

    final flat = weeks.expand((week) => week).toList();
    expect(flat, hasLength(42));
    expect(flat.first.date, CalendarGrid.gridStart(DateTime(2026, 10, 5)));
    expect(flat.last.date, CalendarGrid.gridEnd(DateTime(2026, 10, 5)));

    for (var index = 1; index < flat.length; index++) {
      expect(
        dayCount(flat[index - 1].date, flat[index].date),
        1,
        reason: 'sel grid harus berurutan satu hari',
      );
    }
  });

  test('setiap hari dalam bulan muncul tepat sekali di grid', () {
    for (final month in [
      DateTime(2023, 2, 1),
      DateTime(2024, 2, 1),
      DateTime(2026, 4, 1),
      DateTime(2026, 10, 1),
    ]) {
      final inMonth =
          CalendarGrid.days(month).where((day) => day.isInMonth).toList();
      final lastDay = CalendarGrid.lastOfMonth(month).day;

      expect(inMonth, hasLength(lastDay), reason: 'jumlah hari $month');
      expect(inMonth.first.date.day, 1);
      expect(inMonth.last.date.day, lastDay);
      expect(
        inMonth.every((day) => day.date.month == month.month),
        isTrue,
        reason: 'hanya hari bulan berjalan yang ditandai isInMonth',
      );
    }
  });

  test('bulan 28, 30, dan 31 hari', () {
    expect(CalendarGrid.lastOfMonth(DateTime(2026, 2, 1)).day, 28);
    expect(CalendarGrid.lastOfMonth(DateTime(2026, 4, 1)).day, 30);
    expect(CalendarGrid.lastOfMonth(DateTime(2026, 10, 1)).day, 31);
  });

  test('tahun kabisat: Februari 2024 ada 29 hari, 2023 ada 28 hari', () {
    int inMonthCount(int year) => CalendarGrid.days(DateTime(year, 2, 1))
        .where((day) => day.isInMonth)
        .length;

    expect(inMonthCount(2024), 29);
    expect(inMonthCount(2023), 28);
  });

  test('hari bulan tetangga tetap ada di grid dan ditandai isInMonth false',
      () {
    final days = CalendarGrid.days(DateTime(2026, 10, 1));

    final outsideMonths = days
        .where((day) => !day.isInMonth)
        .map((day) => day.date.month)
        .toSet();

    // Jendela grid 1 Okt 2026 mencakup akhir September dan awal November.
    expect(outsideMonths, {9, 11});
    expect(
      days.where((day) => day.isInMonth).every((day) => day.date.month == 10),
      isTrue,
    );
  });

  test('pindah bulan memakai komponen tanggal bulan sebelumnya/berikutnya', () {
    expect(CalendarGrid.firstOfMonth(DateTime(2026, 1, 31)), DateTime(2026, 1, 1));
    expect(CalendarGrid.lastOfMonth(DateTime(2026, 12, 5)), DateTime(2026, 12, 31));
  });
}
