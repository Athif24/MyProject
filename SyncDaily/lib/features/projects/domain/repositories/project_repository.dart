import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';

abstract class ProjectRepository {
  Stream<List<Project>> watchProjects();

  /// Daftar proyek belum dihapus beserta jumlah tugas dan sub-task-nya.
  Stream<List<ProjectWithCounts>> watchProjectsWithCounts();

  /// Jumlah proyek belum dihapus, dipisah per peran.
  Future<int> countByRole(ProjectRole role);

  Future<Project?> getProject(String id);

  Future<void> upsertProject(Project project);

  /// Soft delete proyek beserta seluruh tugas di dalamnya.
  Future<void> softDeleteProject(String id);
}
