import 'package:equatable/equatable.dart';

/// Ringkasan untuk kartu statistik di Beranda.
///
/// - [today]: item semua tipe yang tanggal acuannya hari ini, belum selesai,
///   belum dihapus. Selalu hari ini (tidak terpengaruh filter periode).
/// - [schedule]: item bertipe event dan reminder dalam periode terpilih
///   (default minggu ini), belum dihapus.
/// - [allTasks]: item bertipe task dan milestone yang belum selesai dan belum
///   dihapus, TANPA sub-task (hanya level atas), tidak dibatasi periode.
/// - [projectsOwned] / [projectsReceived] / [projectsTotal]: jumlah proyek
///   belum dihapus.
class TaskSummary extends Equatable {
  final int today;
  final int schedule;
  final int allTasks;
  final int projectsOwned;
  final int projectsReceived;

  const TaskSummary({
    required this.today,
    required this.schedule,
    required this.allTasks,
    required this.projectsOwned,
    required this.projectsReceived,
  });

  int get projectsTotal => projectsOwned + projectsReceived;

  @override
  List<Object?> get props =>
      [today, schedule, allTasks, projectsOwned, projectsReceived];
}
