import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';

/// Daftar tugas sementara (F4b). Setiap nilai HARUS memakai kriteria yang sama
/// dengan angka kartu statistik Beranda, supaya jumlah item di daftar selalu
/// sama dengan angka di kartunya (lihat `TaskRepositoryImpl._buildSummary`).
enum TaskListFilter {
  /// Kartu "Hari ini": semua tipe, belum selesai, tanggal acuan hari ini.
  /// Termasuk sub-tugas (sub-tugas mewarisi tanggal induknya).
  today,

  /// Kartu "Semua tugas": hanya tipe tugas dan milestone, belum selesai, dan
  /// tanpa sub-tugas (hanya level atas).
  allTasks,
}

/// Satu sumber kriteria untuk angka kartu Beranda dan isi daftar tugas.
class TaskListFilters {
  const TaskListFilters._();

  static bool matches(Task task, TaskListFilter filter, DateTime today) {
    switch (filter) {
      case TaskListFilter.today:
        return task.status != TaskStatus.done &&
            TaskDateUtils.isOnDay(task, today);
      case TaskListFilter.allTasks:
        return (task.type == TaskType.task ||
                task.type == TaskType.milestone) &&
            task.status != TaskStatus.done &&
            task.parentTaskId == null;
    }
  }
}
