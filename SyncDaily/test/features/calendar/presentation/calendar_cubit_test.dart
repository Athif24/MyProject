import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:sync_daily/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

import '../../../helpers/test_repositories.dart';

/// Tes cubit Kalender memakai database Drift in-memory (seperti tes cubit form)
/// agar jalur `watchAllTasks()` + `watchRecurrences()` ikut teruji.
void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;

  final fixedNow = DateTime(2026, 10, 14, 8, 30);
  final ts = DateTime.utc(2026, 1, 1);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = TaskRepositoryImpl(db.tasksDao, db.projectsDao);
  });

  tearDown(() async {
    await db.close();
  });

  CalendarCubit buildCubit({DateTime? now}) => CalendarCubit(
        taskRepository: taskRepo,
        now: () => now ?? fixedNow,
      );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  Task task({
    required String id,
    String title = 'Item',
    TaskType type = TaskType.task,
    TaskStatus status = TaskStatus.todo,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? dueAt,
    bool isAllDay = false,
  }) {
    return Task(
      id: id,
      title: title,
      type: type,
      status: status,
      startAt: startAt,
      endAt: endAt,
      dueAt: dueAt,
      isAllDay: isAllDay,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  test('bulan dan tanggal terpilih awal dari jam injeksi', () async {
    final cubit = buildCubit();

    expect(cubit.state.visibleMonth, DateTime(2026, 10, 1));
    expect(cubit.state.selectedDate, DateTime(2026, 10, 14));
    expect(cubit.state.today, DateTime(2026, 10, 14));
    expect(cubit.state.status, CalendarStatus.loading);

    await cubit.close();
  });

  test('memuat item dan aturan pengulangan dari repository', () async {
    final cubit = buildCubit()..start();
    await settle();

    expect(cubit.state.status, CalendarStatus.loaded);
    expect(cubit.state.agenda, isEmpty);
    expect(cubit.state.daysWithItems, isEmpty);

    await cubit.close();
  });

  test('hari yang punya item tampil di peta titik grid', () async {
    await taskRepo.upsertTask(
      task(id: 't1', title: 'Tugas hari ini', dueAt: DateTime(2026, 10, 14, 9)),
    );
    await taskRepo.upsertTask(
      task(
        id: 'e1',
        title: 'Acara',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 16, 9),
        endAt: DateTime(2026, 10, 16, 10),
      ),
    );

    final cubit = buildCubit()..start();
    await settle();

    expect(cubit.state.daysWithItems[DateTime(2026, 10, 14)], {TaskType.task});
    expect(cubit.state.daysWithItems[DateTime(2026, 10, 16)], {TaskType.event});
    expect(cubit.state.daysWithItems.containsKey(DateTime(2026, 10, 15)),
        isFalse);
    expect(cubit.state.agenda.single.task.id, 't1');

    await cubit.close();
  });

  test('tombol bulan sebelumnya/berikutnya menggeser bulan dan tanggal',
      () async {
    final cubit = buildCubit()..start();
    await settle();

    cubit.previousMonth();
    expect(cubit.state.visibleMonth, DateTime(2026, 9, 1));
    expect(cubit.state.selectedDate, DateTime(2026, 9, 14));

    cubit.nextMonth();
    expect(cubit.state.visibleMonth, DateTime(2026, 10, 1));
    expect(cubit.state.selectedDate, DateTime(2026, 10, 14));

    await cubit.close();
  });

  test('tanggal 31 dipangkas saat pindah ke bulan pendek', () async {
    final cubit = buildCubit(now: DateTime(2026, 3, 31, 7))..start();
    await settle();

    cubit.previousMonth();

    expect(cubit.state.visibleMonth, DateTime(2026, 2, 1));
    expect(cubit.state.selectedDate, DateTime(2026, 2, 28));

    await cubit.close();
  });

  test('memilih tanggal di bulan lain memindahkan grid dan agenda', () async {
    await taskRepo.upsertTask(
      task(id: 'n1', title: 'Proyek November', dueAt: DateTime(2026, 11, 3, 10)),
    );

    final cubit = buildCubit()..start();
    await settle();
    expect(cubit.state.agenda, isEmpty);

    cubit.selectDate(DateTime(2026, 11, 3));

    expect(cubit.state.visibleMonth, DateTime(2026, 11, 1));
    expect(cubit.state.selectedDate, DateTime(2026, 11, 3));
    expect(cubit.state.agenda.single.task.title, 'Proyek November');

    await cubit.close();
  });

  test('item harian muncul tiap hari tanpa menulis salinan baru', () async {
    await taskRepo.upsertTask(
      task(id: 'r1', title: 'Minum obat', dueAt: DateTime(2026, 10, 14, 8)),
    );
    await taskRepo.setRecurrence(
      'r1',
      TaskRecurrence(
        taskId: 'r1',
        frequency: RecurrenceFrequency.daily,
        intervalValue: 1,
        createdAt: ts,
        updatedAt: ts,
      ),
    );

    final cubit = buildCubit()..start();
    await settle();

    expect(cubit.state.agenda.single.task.id, 'r1');
    expect(cubit.state.daysWithItems[DateTime(2026, 10, 20)], {TaskType.task});

    cubit.selectDate(DateTime(2026, 10, 20));
    expect(cubit.state.agenda.single.task.id, 'r1');

    // Tetap satu baris item dan satu aturan: kemunculan tidak disalin ke DB.
    expect(await taskRepo.watchAllTasks().first, hasLength(1));
    expect(await taskRepo.watchRecurrences().first, hasLength(1));

    await cubit.close();
  });

  test('item selesai tetap muncul di agenda', () async {
    await taskRepo.upsertTask(
      task(
        id: 'd1',
        title: 'Sudah selesai',
        dueAt: DateTime(2026, 10, 14, 8),
        status: TaskStatus.done,
      ),
    );

    final cubit = buildCubit()..start();
    await settle();

    expect(cubit.state.agenda.single.task.status, TaskStatus.done);

    await cubit.close();
  });

  test('acara lintas hari muncul di tiap hari yang dilewati', () async {
    await taskRepo.upsertTask(
      task(
        id: 'e1',
        title: 'Rapat luar kota',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 16, 17),
      ),
    );

    final cubit = buildCubit()..start();
    await settle();

    expect(cubit.state.agenda.single.task.id, 'e1');

    cubit.selectDate(DateTime(2026, 10, 15));
    expect(cubit.state.agenda.single.task.id, 'e1');

    cubit.selectDate(DateTime(2026, 10, 16));
    expect(cubit.state.agenda.single.task.id, 'e1');

    await cubit.close();
  });

  test('gagal memuat data membuat status error dan bisa dicoba lagi', () async {
    final failing = MockTaskRepository();
    when(() => failing.watchAllTasks())
        .thenAnswer((_) => Stream<List<Task>>.error(Exception('gagal')));
    when(() => failing.watchRecurrences())
        .thenAnswer((_) => Stream<List<TaskRecurrence>>.value(const []));

    final cubit = CalendarCubit(
      taskRepository: failing,
      now: () => fixedNow,
    )..start();
    await settle();

    expect(cubit.state.status, CalendarStatus.error);
    expect(cubit.state.errorMessage, contains('gagal'));

    cubit.retry();
    expect(cubit.state.status, CalendarStatus.loading);
    await settle();

    await cubit.close();
  });
}
