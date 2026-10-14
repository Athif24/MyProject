import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/projects/data/repositories/project_repository_impl.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ProjectRepository projectRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = TaskRepositoryImpl(db.tasksDao, db.projectsDao);
    projectRepo = ProjectRepositoryImpl(db.projectsDao);
  });

  tearDown(() => db.close());

  DateTime now() => DateTime.now().toUtc();

  Task makeTask({
    required String id,
    TaskType type = TaskType.task,
    TaskStatus status = TaskStatus.todo,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? dueAt,
    String? projectId,
    String? parentTaskId,
    bool isAllDay = false,
    String title = 'Tugas',
  }) {
    final ts = now();
    return Task(
      id: id,
      title: title,
      type: type,
      status: status,
      startAt: startAt,
      endAt: endAt,
      dueAt: dueAt,
      projectId: projectId,
      parentTaskId: parentTaskId,
      isAllDay: isAllDay,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  group('query', () {
    test('watchTodayTasks hanya item hari ini, belum selesai, belum dihapus',
        () async {
      final today = DateTime.now();
      await taskRepo.upsertTask(makeTask(id: 'a', dueAt: today));
      await taskRepo.upsertTask(
        makeTask(id: 'b', dueAt: today, status: TaskStatus.done),
      );
      await taskRepo.upsertTask(
        makeTask(id: 'c', dueAt: today.add(const Duration(days: 3))),
      );

      final result = await taskRepo.watchTodayTasks().first;
      expect(result.map((t) => t.id), ['a']);
    });

    test('watchTasksInRange menyaring berdasarkan rentang', () async {
      final base = DateTime.now();
      await taskRepo.upsertTask(makeTask(id: 'in', dueAt: base));
      await taskRepo.upsertTask(
        makeTask(id: 'out', dueAt: base.add(const Duration(days: 10))),
      );

      final result = await taskRepo
          .watchTasksInRange(base, base.add(const Duration(days: 1)))
          .first;
      expect(result.map((t) => t.id), ['in']);
    });

    test('watchTasksByProject hanya item proyek tersebut', () async {
      await projectRepo.upsertProject(
        Project(
          id: 'p1',
          title: 'Proyek 1',
          createdAt: now(),
          updatedAt: now(),
        ),
      );
      await taskRepo.upsertTask(makeTask(id: 't1', projectId: 'p1'));
      await taskRepo.upsertTask(makeTask(id: 't2'));

      final result = await taskRepo.watchTasksByProject('p1').first;
      expect(result.map((t) => t.id), ['t1']);
    });
  });

  group('ringkasan', () {
    test('menghitung hari ini, jadwal, semua tugas, dan proyek', () async {
      final today = DateTime.now();
      // Hari ini (task).
      await taskRepo.upsertTask(makeTask(id: 'today', dueAt: today));
      // Jadwal (event minggu ini).
      await taskRepo.upsertTask(
        makeTask(id: 'event', type: TaskType.event, startAt: today),
      );
      // Semua tugas (milestone level atas, tanpa tenggat).
      await taskRepo.upsertTask(
        makeTask(id: 'mile', type: TaskType.milestone),
      );
      // Sub-task tidak dihitung di "Semua tugas".
      await taskRepo.upsertTask(
        makeTask(id: 'sub', parentTaskId: 'today'),
      );
      // Selesai tidak dihitung.
      await taskRepo.upsertTask(
        makeTask(id: 'done', type: TaskType.task, status: TaskStatus.done),
      );

      await projectRepo.upsertProject(
        Project(
          id: 'owned',
          title: 'Milik saya',
          role: ProjectRole.owned,
          createdAt: now(),
          updatedAt: now(),
        ),
      );
      await projectRepo.upsertProject(
        Project(
          id: 'recv',
          title: 'Diterima',
          role: ProjectRole.received,
          createdAt: now(),
          updatedAt: now(),
        ),
      );

      final summary = await taskRepo.getSummary();

      expect(summary.today, 2); // 'today' + 'event' (keduanya bertanggal kini)
      expect(summary.schedule, 1);
      expect(summary.allTasks, 2); // 'today' + 'mile'
      expect(summary.projectsOwned, 1);
      expect(summary.projectsReceived, 1);
      expect(summary.projectsTotal, 2);
    });
  });

  group('status', () {
    test('setStatus mengisi completedAt lalu mengosongkannya', () async {
      await taskRepo.upsertTask(makeTask(id: 'a'));

      await taskRepo.setStatus('a', TaskStatus.done);
      final done = await taskRepo.getTask('a');
      expect(done!.status, TaskStatus.done);
      expect(done.completedAt, isNotNull);

      await taskRepo.setStatus('a', TaskStatus.todo);
      final reopened = await taskRepo.getTask('a');
      expect(reopened!.status, TaskStatus.todo);
      expect(reopened.completedAt, isNull);
    });
  });

  group('soft delete', () {
    test('soft delete tugas menandai seluruh sub-task', () async {
      await taskRepo.upsertTask(makeTask(id: 'root'));
      await taskRepo.upsertTask(makeTask(id: 'child', parentTaskId: 'root'));
      await taskRepo.upsertTask(
        makeTask(id: 'grand', parentTaskId: 'child'),
      );

      await taskRepo.softDeleteTask('root');

      final active = await taskRepo.watchAllTasks().first;
      expect(active, isEmpty);

      final rootRow = await db.tasksDao.getById('root');
      final childRow = await db.tasksDao.getById('child');
      final grandRow = await db.tasksDao.getById('grand');
      expect(rootRow!.deletedAt, isNotNull);
      expect(childRow!.deletedAt, isNotNull);
      expect(grandRow!.deletedAt, isNotNull);
    });

    test('soft delete proyek menandai seluruh tugas proyek', () async {
      await projectRepo.upsertProject(
        Project(
          id: 'p1',
          title: 'Proyek',
          createdAt: now(),
          updatedAt: now(),
        ),
      );
      await taskRepo.upsertTask(makeTask(id: 't1', projectId: 'p1'));
      await taskRepo.upsertTask(makeTask(id: 't2', projectId: 'p1'));
      await taskRepo.upsertTask(makeTask(id: 'other'));

      await projectRepo.softDeleteProject('p1');

      final tasks = await taskRepo.watchAllTasks().first;
      expect(tasks.map((t) => t.id), ['other']);

      final project = await projectRepo.getProject('p1');
      expect(project!.deletedAt, isNotNull);
    });
  });

  group('reminder & recurrence', () {
    test('mengganti daftar pengingat', () async {
      await taskRepo.upsertTask(makeTask(id: 'a'));
      final ts = now();

      await taskRepo.replaceReminders('a', [
        TaskReminder(
          id: 'r1',
          taskId: 'a',
          offsetMinutes: 10,
          createdAt: ts,
          updatedAt: ts,
        ),
        TaskReminder(
          id: 'r2',
          taskId: 'a',
          offsetMinutes: 60,
          createdAt: ts,
          updatedAt: ts,
        ),
      ]);

      final reminders = await taskRepo.getReminders('a');
      expect(reminders.map((r) => r.offsetMinutes), [10, 60]);

      await taskRepo.replaceReminders('a', [
        TaskReminder(
          id: 'r3',
          taskId: 'a',
          offsetMinutes: 0,
          createdAt: ts,
          updatedAt: ts,
        ),
      ]);
      final updated = await taskRepo.getReminders('a');
      expect(updated.map((r) => r.offsetMinutes), [0]);
    });

    test('menyimpan dan menghapus aturan pengulangan (bitmask)', () async {
      await taskRepo.upsertTask(makeTask(id: 'a'));
      final ts = now();

      await taskRepo.setRecurrence(
        'a',
        TaskRecurrence(
          taskId: 'a',
          frequency: RecurrenceFrequency.weekly,
          byWeekdays: const {Weekday.monday, Weekday.friday},
          createdAt: ts,
          updatedAt: ts,
        ),
      );

      final rule = await taskRepo.getRecurrence('a');
      expect(rule!.frequency, RecurrenceFrequency.weekly);
      expect(rule.byWeekdays, {Weekday.monday, Weekday.friday});

      await taskRepo.setRecurrence('a', null);
      expect(await taskRepo.getRecurrence('a'), isNull);
    });
  });

  group('all-day', () {
    test('tanggal kalender tidak bergeser', () async {
      await taskRepo.upsertTask(
        makeTask(
          id: 'allday',
          isAllDay: true,
          dueAt: DateTime.utc(2026, 10, 14),
        ),
      );

      final task = await taskRepo.getTask('allday');
      expect(task!.isAllDay, isTrue);
      expect(task.dueAt!.toUtc(), DateTime.utc(2026, 10, 14));
    });
  });
}
