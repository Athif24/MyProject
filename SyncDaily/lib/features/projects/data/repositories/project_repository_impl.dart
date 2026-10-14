import 'package:sync_daily/features/projects/data/daos/projects_dao.dart';
import 'package:sync_daily/features/projects/data/mappers/project_mapper.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectsDao _dao;

  ProjectRepositoryImpl(this._dao);

  @override
  Stream<List<Project>> watchProjects() {
    return _dao
        .watchProjects()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Stream<List<ProjectWithCounts>> watchProjectsWithCounts() {
    return _dao.watchProjectsWithCounts();
  }

  @override
  Future<int> countByRole(ProjectRole role) => _dao.countByRole(role);

  @override
  Future<Project?> getProject(String id) async {
    final row = await _dao.getById(id);
    return row?.toEntity();
  }

  @override
  Future<void> upsertProject(Project project) =>
      _dao.upsertProject(project.toCompanion());

  @override
  Future<void> softDeleteProject(String id) =>
      _dao.softDeleteProjectCascade(id, DateTime.now().toUtc());
}
