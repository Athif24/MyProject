import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';

/// Aturan penentuan waktu untuk tugas, dipakai bersama oleh DAO/repository
/// dan pengingat lokal.
class TaskDateUtils {
  const TaskDateUtils._();

  /// Tanggal acuan untuk pengelompokan "hari ini" dan rentang tanggal.
  ///
  /// - Item [Task.isAllDay] disimpan sebagai UTC tengah malam untuk tanggal
  ///   kalendernya dan ditampilkan TANPA konversi zona waktu, agar tidak
  ///   bergeser sehari. Karena itu tanggalnya diambil apa adanya.
  /// - Item lain memakai prioritas `dueAt`, lalu `startAt`, lalu `endAt`
  ///   dan dikonversi ke zona waktu perangkat.
  static DateTime? referenceDate(Task task) {
    final raw = task.dueAt ?? task.startAt ?? task.endAt;
    if (raw == null) {
      return null;
    }
    if (task.isAllDay) {
      final utc = raw.toUtc();
      return DateTime.utc(utc.year, utc.month, utc.day);
    }
    final local = raw.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool isOnDay(Task task, DateTime day) {
    final reference = referenceDate(task);
    if (reference == null) {
      return false;
    }
    return reference.year == day.year &&
        reference.month == day.month &&
        reference.day == day.day;
  }

  /// Urutan tanggal kalender (tahun, bulan, hari) dua waktu, mengabaikan jam
  /// dan zona waktu: negatif bila [a] lebih awal, 0 bila sama, positif bila
  /// [a] lebih akhir.
  static int compareCalendarDate(DateTime a, DateTime b) {
    if (a.year != b.year) {
      return a.year.compareTo(b.year);
    }
    if (a.month != b.month) {
      return a.month.compareTo(b.month);
    }
    return a.day.compareTo(b.day);
  }

  /// True bila [reference] berada dalam rentang tanggal [start] sampai [end]
  /// (inklusif). Batas dibandingkan sebagai tanggal kalender, BUKAN instan
  /// waktu, supaya item all-day (disimpan sebagai UTC tengah malam) tidak
  /// bergeser karena zona waktu perangkat. [start]/[end] `null` berarti tanpa
  /// batas di sisi tersebut.
  static bool isWithinPeriod(DateTime reference, DateTime? start, DateTime? end) {
    if (start != null && compareCalendarDate(reference, start) < 0) {
      return false;
    }
    if (end != null && compareCalendarDate(reference, end) > 0) {
      return false;
    }
    return true;
  }

  static bool isInRange(Task task, DateTime from, DateTime to) {
    final reference = referenceDate(task);
    if (reference == null) {
      return false;
    }
    return isWithinPeriod(reference, from, to);
  }

  /// Waktu pengingat berbunyi.
  ///
  /// Titik acuan: `startAt` bila ada, jika tidak `dueAt`. Untuk item bertipe
  /// `reminder`, waktunya sendiri adalah titik acuan sehingga offset 0 sah
  /// (mengembalikan waktu tugas itu sendiri).
  static DateTime? reminderTimeFor(Task task, TaskReminder reminder) {
    final base = task.startAt ?? task.dueAt;
    if (base == null) {
      return null;
    }
    return base.subtract(Duration(minutes: reminder.offsetMinutes));
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Rentang minggu berjalan (Senin 00:00 sampai Minggu 23:59:59), berdasarkan
  /// waktu lokal perangkat.
  static ({DateTime start, DateTime end}) weekRange(DateTime reference) {
    final date = _dateOnly(reference);
    final start = date.subtract(Duration(days: reference.weekday - 1));
    final end = start
        .add(const Duration(days: 6))
        .add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }

  /// Rentang bulan berjalan (tanggal 1 sampai hari terakhir bulan), berdasarkan
  /// waktu lokal perangkat.
  static ({DateTime start, DateTime end}) monthRange(DateTime reference) {
    final start = DateTime(reference.year, reference.month, 1);
    final end = DateTime(reference.year, reference.month + 1, 0)
        .add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }
}
