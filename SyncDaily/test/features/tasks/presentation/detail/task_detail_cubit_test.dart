import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/projects/data/repositories/project_repository_impl.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_list_filter.dart';
import 'package:sync_daily/features/tasks/presentation/detail/cubit/task_detail_cubit.dart';
import 'package:sync_daily/features/tasks/presentation/detail/cubit/task_detail_state.dart';
import 'package:sync_daily/features/tasks/presentation/list/cubit/task_list_cubit.dart';

import '../../../../helpers/test_repositories.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ProjectRepository projectRepo;

  final fixedNow = DateTime(2026, 10, 14, 8, 30);
  final today = DateTime(2026, 10, 14);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = TaskRepositoryImpl(db.tasksDao, db.projectsDao);
    projectRepo = ProjectRepositoryImpl(db.projectsDao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(Task task) => taskRepo.upsertTask(task);

  Task subtask(String id, String parentId) => Task(
        id: id,
        parentTaskId: parentId,
        title: 'Sub $id',
        type: TaskType.task,
        dueAt: today.add(const Duration(hours: 9)),
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      );

  Future<TaskDetailCubit> startCubit(String taskId) async {
    final cubit = TaskDetailCubit(
      taskId: taskId,
      taskRepository: taskRepo,
      projectRepository: projectRepo,
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return cubit;
  }

  test('ubah status dan centang sub-tugas', () async {
    await seed(Task(
      id: 'p1',
      title: 'Induk',
      type: TaskType.task,
      dueAt: today.add(const Duration(hours: 9)),
      createdAt: fixedNow.toUtc(),
      updatedAt: fixedNow.toUtc(),
    ));
    await seed(subtask('s1', 'p1'));
    await seed(subtask('s2', 'p1'));

    final cubit = await startCubit('p1');
    expect(cubit.state.status, TaskDetailStatus.loaded);
    expect(cubit.state.subtasks, hasLength(2));
    expect(cubit.state.isDone, isFalse);

    await cubit.toggleStatus();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.isDone, isTrue);
    expect((await taskRepo.getTask('p1'))!.status, TaskStatus.done);

    await cubit.toggleSubtask('s1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect((await taskRepo.getTask('s1'))!.status, TaskStatus.done);
    expect((await taskRepo.getTask('s2'))!.status, TaskStatus.todo);
    await cubit.close();
  });

  test('hapus induk menghapus sub-tugas dan undo memulihkan keduanya', () async {
    await seed(Task(
      id: 'p1',
      title: 'Induk',
      type: TaskType.task,
      dueAt: today.add(const Duration(hours: 9)),
      createdAt: fixedNow.toUtc(),
      updatedAt: fixedNow.toUtc(),
    ));
    await seed(subtask('s1', 'p1'));
    await seed(subtask('s2', 'p1'));
    // Cucu untuk membuktikan cascade berulang.
    await seed(Task(
      id: 'g1',
      parentTaskId: 's1',
      title: 'Cucu',
      type: TaskType.task,
      dueAt: today.add(const Duration(hours: 9)),
      createdAt: fixedNow.toUtc(),
      updatedAt: fixedNow.toUtc(),
    ));

    final before = await taskRepo.getSummary(today: fixedNow);
    expect(before.today, 4);
    expect(before.allTasks, 1);

    final taskList = TaskListCubit(
      taskRepository: taskRepo,
      filter: TaskListFilter.today,
      now: () => fixedNow,
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(taskList.state.tasks, hasLength(before.today));

    final detail = await startCubit('p1');
    final deletedIds = await detail.delete();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Induk + seluruh turunan terhapus.
    expect(deletedIds, containsAll(['p1', 's1', 's2', 'g1']));
    expect(deletedIds, hasLength(4));
    expect(await taskRepo.watchAllTasks().first, isEmpty);

    // Angka kartu dan isi daftar tidak lagi menghitung induk maupun sub-tugas.
    final afterDelete = await taskRepo.getSummary(today: fixedNow);
    expect(afterDelete.today, 0);
    expect(afterDelete.allTasks, 0);
    expect(taskList.state.tasks, isEmpty);

    // "Urungkan".
    await taskList.restore(deletedIds);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(await taskRepo.watchAllTasks().first, hasLength(4));
    final afterUndo = await taskRepo.getSummary(today: fixedNow);
    expect(afterUndo.today, before.today);
    expect(afterUndo.allTasks, before.allTasks);
    expect(taskList.state.tasks, hasLength(before.today));

    await detail.close();
    await taskList.close();
  });

  // Butir 1: baris yang hilang dari `watchAllTasks()` saat hapus berjalan tidak
  // boleh mengubah status menjadi "tidak ditemukan" (kilatan sebelum kembali).
  test('status tetap "sedang menghapus" walau aliran data memancarkan daftar tanpa item',
      () async {
    final taskRepository = MockTaskRepository();
    final projectRepository = MockProjectRepository();
    final tasks = StreamController<List<Task>>();
    final pendingDelete = Completer<List<String>>();
    addTearDown(tasks.close);

    final task = Task(
      id: 'p1',
      title: 'Induk',
      type: TaskType.task,
      dueAt: today.add(const Duration(hours: 9)),
      createdAt: fixedNow.toUtc(),
      updatedAt: fixedNow.toUtc(),
    );

    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => tasks.stream);
    when(() => projectRepository.watchProjects())
        .thenAnswer((_) => Stream<List<Project>>.value(const []));
    when(() => taskRepository.getReminders('p1'))
        .thenAnswer((_) async => []);
    when(() => taskRepository.getRecurrence('p1'))
        .thenAnswer((_) async => null);
    when(() => taskRepository.softDeleteTask('p1'))
        .thenAnswer((_) => pendingDelete.future);

    final cubit = TaskDetailCubit(
      taskId: 'p1',
      taskRepository: taskRepository,
      projectRepository: projectRepository,
    )..start();

    tasks.add([task]);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(cubit.state.status, TaskDetailStatus.loaded);

    final deleted = cubit.delete();
    expect(cubit.state.status, TaskDetailStatus.deleting);

    // Baris induk hilang dari aliran data sebelum halaman ditutup.
    tasks.add(const []);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.status, TaskDetailStatus.deleting);
    expect(cubit.state.task?.id, 'p1');

    pendingDelete.complete(['p1']);
    expect(await deleted, ['p1']);
    await cubit.close();
  });

  test('hapus gagal: status menjadi galat dan halaman tidak ditutup',
      () async {
    final taskRepository = MockTaskRepository();
    final projectRepository = MockProjectRepository();

    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream<List<Task>>.value(const []));
    when(() => projectRepository.watchProjects())
        .thenAnswer((_) => Stream<List<Project>>.value(const []));
    when(() => taskRepository.getReminders('p1'))
        .thenAnswer((_) async => []);
    when(() => taskRepository.getRecurrence('p1'))
        .thenAnswer((_) async => null);
    when(() => taskRepository.softDeleteTask('p1'))
        .thenAnswer((_) => Future<List<String>>.error(StateError('gagal')));

    final cubit = TaskDetailCubit(
      taskId: 'p1',
      taskRepository: taskRepository,
      projectRepository: projectRepository,
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await expectLater(cubit.delete(), throwsA(isA<StateError>()));
    expect(cubit.state.status, TaskDetailStatus.error);
    await cubit.close();
  });
}
