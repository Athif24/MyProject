import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sync_daily/core/strings/app_strings.dart';

/// Pemformat tanggal/waktu berbahasa Indonesia (`id_ID`), sesuai DESIGN.md.
///
/// Data locale `id_ID` perlu dimuat sekali sebelum dipakai; panggil
/// [ensureInitialized] saat aplikasi mulai (dan di `setUpAll` pengujian).
class IdDate {
  const IdDate._();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await initializeDateFormatting('id_ID');
    _initialized = true;
  }

  /// Contoh: `14 Okt`.
  static String dayMonth(DateTime date) =>
      DateFormat('d MMM', 'id_ID').format(date);

  /// Contoh: `14 Okt 2026`.
  static String full(DateTime date) =>
      DateFormat('d MMM yyyy', 'id_ID').format(date);

  /// Contoh: `Oktober 2026` (judul bulan Kalender).
  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);

  /// Contoh: `Sen` (kepala kolom grid bulan, `id_ID`).
  static String weekdayShort(DateTime date) =>
      DateFormat('E', 'id_ID').format(date);

  /// Tanggal ISO `YYYY-MM-DD` untuk parameter `?date=` pada rute form.
  static String isoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Rentang tanggal ringkas: `14 Okt` bila sama, `14 – 20 Okt` bila satu bulan,
  /// atau `28 Sep – 3 Okt` bila berbeda bulan.
  static String range(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return AppStrings.withoutDate;
    }
    if (start != null && end == null) {
      return dayMonth(start);
    }
    if (start == null && end != null) {
      return dayMonth(end);
    }
    final from = start!;
    final to = end!;
    if (from.year == to.year &&
        from.month == to.month &&
        from.day == to.day) {
      return dayMonth(from);
    }
    if (from.year == to.year && from.month == to.month) {
      return '${from.day} – ${dayMonth(to)}';
    }
    return '${dayMonth(from)} – ${dayMonth(to)}';
  }
}
