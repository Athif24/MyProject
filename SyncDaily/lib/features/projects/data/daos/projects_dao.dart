import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/projects/data/database/projects_table.dart';
import 'package:sync_daily/features/projects/data/mappers/project_mapper.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';
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

  /// Proyek belum dihapus + jumlah tugas (level atas) dan sub-task.
  Stream<List<ProjectWithCounts>> watchProjectsWithCounts() {
    final taskCount = tasks.id.count(
      filter: tasks.deletedAt.isNull() & tasks.parentTaskId.isNull(),
    );
    final subtaskCount = tasks.id.count(
      filter: tasks.deletedAt.isNull() & tasks.parentTaskId.isNotNull(),
    );

    final query = select(projects).join([
      leftOuterJoin(tasks, tasks.projectId.equalsExp(projects.id)),
    ]);
    query
      ..where(projects.deletedAt.isNull())
      ..groupBy([projects.id])
      ..orderBy([OrderingTerm.asc(projects.title)]);
    query.addColumns([taskCount, subtaskCount]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => ProjectWithCounts(
                  project: row.readTable(projects).toEntity(),
                  taskCount: row.read(taskCount) ?? 0,
                  subtaskCount: row.read(subtaskCount) ?? 0,
                ),
              )
              .toList(),
        );
  }

  /// Jumlah proyek belum dihapus per peran, sebagai satu stream reaktif.
  Stream<({int owned, int received})> watchRoleCounts() {
    final owned = projects.id.count(
      filter: projects.deletedAt.isNull() &
          projects.role.equalsValue(ProjectRole.owned),
    );
    final received = projects.id.count(
      filter: projects.deletedAt.isNull() &
          projects.role.equalsValue(ProjectRole.received),
    );

    final query = selectOnly(projects)..addColumns([owned, received]);
    return query.watchSingle().map(
          (row) => (
            owned: row.read(owned) ?? 0,
            received: row.read(received) ?? 0,
          ),
        );
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
