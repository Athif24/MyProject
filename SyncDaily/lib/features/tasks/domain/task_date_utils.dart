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

  static bool isInRange(Task task, DateTime from, DateTime to) {
    final reference = referenceDate(task);
    if (reference == null) {
      return false;
    }
    return !reference.isBefore(_dateOnly(from)) &&
        !reference.isAfter(_dateOnly(to));
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
}
