import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_list_filter.dart';
import 'package:sync_daily/features/tasks/presentation/list/cubit/task_list_cubit.dart';
import 'package:sync_daily/features/tasks/presentation/list/cubit/task_list_state.dart';

/// Membuktikan isi daftar memakai kriteria yang sama dengan angka kartu
/// Beranda ("Hari ini" dan "Semua tugas").
void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;

  final fixedNow = DateTime(2026, 10, 14, 8, 30);
  final today = DateTime(2026, 10, 14);
  final nextWeek = DateTime(2026, 10, 20);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = TaskRepositoryImpl(db.tasksDao, db.projectsDao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed(Task task) => taskRepo.upsertTask(task);

  Task taskAt(
    String id, {
    TaskType type = TaskType.task,
    TaskStatus status = TaskStatus.todo,
    String? parentTaskId,
    DateTime? dueAt,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    return Task(
      id: id,
      parentTaskId: parentTaskId,
      title: 'Item $id',
      type: type,
      status: status,
      dueAt: dueAt,
      startAt: startAt,
      endAt: endAt,
      createdAt: fixedNow.toUtc(),
      updatedAt: fixedNow.toUtc(),
    );
  }

  Future<TaskListCubit> startCubit(TaskListFilter filter) async {
    final cubit = TaskListCubit(
      taskRepository: taskRepo,
      filter: filter,
      now: () => fixedNow,
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return cubit;
  }

  /// Data campuran: tugas induk + sub-tugas (hari ini), acara & pengingat hari
  /// ini, milestone hari ini, satu tugas selesai, dan item pekan depan.
  Future<void> seedMixed() async {
    await seed(taskAt('t1', dueAt: today.add(const Duration(hours: 9))));
    await seed(taskAt(
      's1',
      parentTaskId: 't1',
      dueAt: today.add(const Duration(hours: 9)),
    ));
    await seed(taskAt(
      'e1',
      type: TaskType.event,
      startAt: today.add(const Duration(hours: 10)),
    ));
    await seed(taskAt(
      'r1',
      type: TaskType.reminder,
      startAt: today.add(const Duration(hours: 7)),
    ));
    await seed(taskAt('m1', type: TaskType.milestone, dueAt: today));
    await seed(taskAt(
      'd1',
      status: TaskStatus.done,
      dueAt: today.add(const Duration(hours: 9)),
    ));
    await seed(taskAt('f1', dueAt: nextWeek));
    await seed(taskAt('f2', type: TaskType.event, startAt: nextWeek));
  }

  test('jumlah item daftar Hari ini sama dengan angka kartu', () async {
    await seedMixed();

    final summary = await taskRepo.getSummary(today: fixedNow);
    final cubit = await startCubit(TaskListFilter.today);

    expect(cubit.state.status, TaskListStatus.loaded);
    expect(cubit.state.tasks, hasLength(summary.today));
    // Termasuk sub-tugas dan item non-tugas, sama seperti angka kartu.
    expect(
      cubit.state.tasks.map((t) => t.id),
      containsAll(['t1', 's1', 'e1', 'r1', 'm1']),
    );
    await cubit.close();
  });

  test('jumlah item daftar Semua tugas sama dengan angka kartu', () async {
    await seedMixed();

    final summary = await taskRepo.getSummary(today: fixedNow);
    final cubit = await startCubit(TaskListFilter.allTasks);

    expect(cubit.state.status, TaskListStatus.loaded);
    expect(cubit.state.tasks, hasLength(summary.allTasks));
    // Hanya tugas/milestone level atas yang belum selesai.
    expect(
      cubit.state.tasks.map((t) => t.id),
      containsAll(['t1', 'm1', 'f1']),
    );
    expect(cubit.state.tasks.map((t) => t.id), isNot(contains('s1')));
    await cubit.close();
  });
}
