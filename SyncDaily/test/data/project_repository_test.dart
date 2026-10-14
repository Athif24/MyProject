import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/projects/data/repositories/project_repository_impl.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepo;
  late TaskRepository taskRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    projectRepo = ProjectRepositoryImpl(db.projectsDao);
    taskRepo = TaskRepositoryImpl(db.tasksDao, db.projectsDao);
  });

  tearDown(() => db.close());

  DateTime now() => DateTime.now().toUtc();

  Project makeProject({
    required String id,
    ProjectRole? role,
    String title = 'Proyek',
  }) {
    return Project(
      id: id,
      title: title,
      role: role,
      createdAt: now(),
      updatedAt: now(),
    );
  }

  Task makeTask({
    required String id,
    String? projectId,
    String? parentTaskId,
    String title = 'Tugas',
  }) {
    return Task(
      id: id,
      projectId: projectId,
      parentTaskId: parentTaskId,
      title: title,
      type: TaskType.task,
      createdAt: now(),
      updatedAt: now(),
    );
  }

  group('watchProjectsWithCounts', () {
    test('menghitung tugas level atas dan sub-task per proyek', () async {
      await projectRepo.upsertProject(makeProject(id: 'p1', role: ProjectRole.owned));
      await projectRepo.upsertProject(makeProject(id: 'p2', role: ProjectRole.received));

      await taskRepo.upsertTask(makeTask(id: 't1', projectId: 'p1'));
      await taskRepo.upsertTask(makeTask(id: 't2', projectId: 'p1'));
      await taskRepo.upsertTask(
        makeTask(id: 's1', projectId: 'p1', parentTaskId: 't1'),
      );
      await taskRepo.upsertTask(makeTask(id: 't3', projectId: 'p2'));

      final result = await projectRepo.watchProjectsWithCounts().first;
      final byId = {for (final item in result) item.project.id: item};

      expect(byId['p1']!.taskCount, 2);
      expect(byId['p1']!.subtaskCount, 1);
      expect(byId['p2']!.taskCount, 1);
      expect(byId['p2']!.subtaskCount, 0);
    });

    test('tidak menyertakan proyek atau tugas yang sudah dihapus', () async {
      await projectRepo.upsertProject(makeProject(id: 'p1'));
      await taskRepo.upsertTask(makeTask(id: 't1', projectId: 'p1'));

      await projectRepo.softDeleteProject('p1');

      final result = await projectRepo.watchProjectsWithCounts().first;
      expect(result, isEmpty);
    });
  });

  test('watchRoleCounts memisah jumlah per peran', () async {
    await projectRepo.upsertProject(makeProject(id: 'o1', role: ProjectRole.owned));
    await projectRepo.upsertProject(makeProject(id: 'o2', role: ProjectRole.owned));
    await projectRepo.upsertProject(makeProject(id: 'r1', role: ProjectRole.received));

    final counts = await db.projectsDao.watchRoleCounts().first;
    expect(counts.owned, 2);
    expect(counts.received, 1);
  });
}
