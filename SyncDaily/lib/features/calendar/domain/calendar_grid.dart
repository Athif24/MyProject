/// Tanggal tanpa jam (waktu lokal). Dipakai sebagai kunci hari di Kalender.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Tanggal kalender dari komponen UTC (untuk item seharian, lihat
/// `TaskDateUtils.referenceDate`).
DateTime utcDateOnly(DateTime value) {
  final utc = value.toUtc();
  return DateTime(utc.year, utc.month, utc.day);
}

/// Tanggal kalender dari waktu lokal perangkat (untuk item berjam).
DateTime localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// [date] digeser [days] hari memakai komponen tanggal (bukan `Duration`) agar
/// tetap tengah malam lokal pada zona waktu ber-DST.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Jumlah hari kalender antara [from] dan [to] (selisih tanggal saja), dihitung
/// lewat UTC agar tidak terpengaruh DST pada zona waktu perangkat.
int dayCount(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Satu sel grid bulan Kalender.
class CalendarDay {
  /// Tanggal sel (tanpa jam, waktu lokal).
  final DateTime date;

  /// True bila [date] berada di bulan yang sedang ditampilkan.
  final bool isInMonth;

  const CalendarDay({required this.date, required this.isInMonth});

  @override
  bool operator ==(Object other) =>
      other is CalendarDay &&
      other.date == date &&
      other.isInMonth == isInMonth;

  @override
  int get hashCode => Object.hash(date, isInMonth);

  @override
  String toString() => 'CalendarDay($date, inMonth: $isInMonth)';
}

/// Pembuat grid bulan untuk layar Kalender.
///
/// Awal pekan adalah SENIN, konsisten dengan `TaskDateUtils.weekRange`,
/// `RecurrenceCalculator`, dan `enum Weekday` (index 0 = Senin).
class CalendarGrid {
  const CalendarGrid._();

  static const int daysPerWeek = 7;

  /// Jumlah baris tetap supaya tinggi grid tidak melompat saat pindah bulan.
  static const int weeksPerMonth = 6;

  /// Senin pada pekan yang memuat [value].
  ///
  /// Memakai aritmetika komponen tanggal (bukan `Duration`) agar hasilnya tetap
  /// tengah malam lokal pada zona waktu ber-DST.
  static DateTime startOfWeek(DateTime value) {
    final date = dateOnly(value);
    return DateTime(date.year, date.month, date.day - (value.weekday - 1));
  }

  /// Tanggal 1 pada bulan [month].
  static DateTime firstOfMonth(DateTime month) =>
      DateTime(month.year, month.month, 1);

  /// Hari terakhir pada bulan [month].
  static DateTime lastOfMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  /// Sel pertama grid (Senin sebelum/tepat tanggal 1).
  static DateTime gridStart(DateTime month) =>
      startOfWeek(firstOfMonth(month));

  /// Sel terakhir grid.
  static DateTime gridEnd(DateTime month) {
    final start = gridStart(month);
    return DateTime(
      start.year,
      start.month,
      start.day + daysPerWeek * weeksPerMonth - 1,
    );
  }

  /// Seluruh tanggal yang ditampilkan grid, termasuk hari bulan tetangga
  /// (diredupkan di UI).
  static List<CalendarDay> days(DateTime month) {
    final first = firstOfMonth(month);
    final start = startOfWeek(first);
    return [
      for (var index = 0; index < daysPerWeek * weeksPerMonth; index++)
        _dayAt(addDays(start, index), first),
    ];
  }

  /// Grid 6 baris x 7 kolom.
  static List<List<CalendarDay>> weeks(DateTime month) {
    final all = days(month);
    return [
      for (var row = 0; row < weeksPerMonth; row++)
        all.sublist(row * daysPerWeek, (row + 1) * daysPerWeek),
    ];
  }

  static CalendarDay _dayAt(DateTime date, DateTime firstOfMonth) => CalendarDay(
        date: date,
        isInMonth: date.year == firstOfMonth.year &&
            date.month == firstOfMonth.month,
      );
}
