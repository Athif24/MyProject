import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';

/// Proyek beserta jumlah tugas untuk daftar di Beranda.
///
/// - [taskCount]: tugas level atas (tanpa induk) yang belum dihapus.
/// - [subtaskCount]: sub-task (punya induk) yang belum dihapus.
class ProjectWithCounts extends Equatable {
  final Project project;
  final int taskCount;
  final int subtaskCount;

  const ProjectWithCounts({
    required this.project,
    required this.taskCount,
    required this.subtaskCount,
  });

  @override
  List<Object?> get props => [project, taskCount, subtaskCount];
}
