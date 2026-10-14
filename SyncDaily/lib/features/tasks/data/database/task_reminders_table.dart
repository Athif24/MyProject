import 'package:drift/drift.dart';
import 'package:sync_daily/features/tasks/data/database/tasks_table.dart';

/// Daftar pengingat per tugas (1:N). Alasan tabel terpisah: tiap offset bisa
/// dijadwalkan/diedit sendiri, cocok dengan `reminderOffsetsMinutes[]` API,
/// tidak ada teks yang dipisah koma, dan ikut terhapus saat tugas dihapus.
@DataClassName('TaskReminderRow')
class TaskReminders extends Table {
  TextColumn get id => text()();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Menit sebelum titik acuan (startAt bila ada, jika tidak dueAt).
  IntColumn get offsetMinutes => integer()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
