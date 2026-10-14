import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/projects/data/database/projects_table.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/tasks/data/database/tasks_table.dart';

part 'projects_dao.g.dart';

@DriftAccessor(tables: [Projects, Tasks])
class ProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  Stream<List<ProjectRow>> watchProjects() {
    return (select(projects)
          ..where((p) => p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.title)]))
        .watch();
  }

  Future<int> countByRole(ProjectRole role) async {
    final count = projects.id.count();
    final query = selectOnly(projects)
      ..addColumns([count])
      ..where(projects.deletedAt.isNull() & projects.role.equalsValue(role));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<ProjectRow?> getById(String id) {
    return (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertProject(ProjectsCompanion companion) {
    return into(projects).insertOnConflictUpdate(companion);
  }

  /// Soft delete proyek beserta seluruh tugas di dalamnya.
  Future<void> softDeleteProjectCascade(String id, DateTime now) async {
    await (update(projects)..where((p) => p.id.equals(id))).write(
      ProjectsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await (update(tasks)
          ..where((t) => t.projectId.equals(id) & t.deletedAt.isNull()))
        .write(
      TasksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
