import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';

/// Menyembunyikan sumber data (Drift) dari UI. Implementasi ada di lapisan data
/// sehingga sinkronisasi server bisa ditambahkan tanpa mengubah UI.
abstract class TaskRepository {
  /// Item semua tipe yang tanggal acuannya hari ini, belum selesai, belum
  /// dihapus.
  Stream<List<Task>> watchTodayTasks();

  /// Item yang tanggal acuannya berada dalam `[from, to]` (inklusif), belum
  /// dihapus.
  Stream<List<Task>> watchTasksInRange(DateTime from, DateTime to);

  /// Item milik satu proyek, belum dihapus.
  Stream<List<Task>> watchTasksByProject(String projectId);

  /// Semua item belum dihapus (dipakai untuk sub-task dan daftar umum).
  Stream<List<Task>> watchAllTasks();

  Future<Task?> getTask(String id);

  Future<TaskSummary> getSummary({DateTime? periodStart, DateTime? periodEnd});

  Future<void> upsertTask(Task task);

  /// Mengubah status. Saat menjadi [TaskStatus.done], `completedAt` diisi;
  /// saat berubah dari done, `completedAt` dikosongkan.
  Future<void> setStatus(String id, TaskStatus status);

  /// Soft delete tugas beserta seluruh sub-task turunannya.
  Future<void> softDeleteTask(String id);

  Future<List<TaskReminder>> getReminders(String taskId);

  /// Mengganti seluruh daftar pengingat milik tugas.
  Future<void> replaceReminders(String taskId, List<TaskReminder> reminders);

  Future<TaskRecurrence?> getRecurrence(String taskId);

  /// Menyimpan aturan pengulangan. Mengirim `null` menghapus aturan.
  Future<void> setRecurrence(String taskId, TaskRecurrence? recurrence);
}
