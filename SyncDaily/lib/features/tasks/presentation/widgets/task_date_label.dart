import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';

/// Jam dalam format `HH.mm` (tanpa konversi zona; pemanggil mengirim waktu
/// lokal).
String clockLabel(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}

/// Tanggal/jam satu kolom tanggal mengikuti aturan `TaskDateUtils`:
/// item sepanjang hari hanya menampilkan tanggal (tanpa konversi zona), item
/// berjam menambahkan jam lokal.
String taskFieldDateTime(DateTime? value, {required bool isAllDay}) {
  if (value == null) {
    return AppStrings.withoutDate;
  }
  if (isAllDay) {
    final utc = value.toUtc();
    return IdDate.full(DateTime(utc.year, utc.month, utc.day));
  }
  final local = value.toLocal();
  return '${IdDate.full(local)} · ${clockLabel(local)}';
}

/// Tanggal/jam ringkas sebuah item, memakai tanggal acuan `dueAt`/`startAt`/
/// `endAt` seperti `TaskDateUtils.referenceDate`.
String taskDateLabel(Task task) {
  final raw = task.dueAt ?? task.startAt ?? task.endAt;
  return taskFieldDateTime(raw, isAllDay: task.isAllDay);
}
