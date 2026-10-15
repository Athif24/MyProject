import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/projects/data/repositories/project_repository_impl.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';
import 'package:sync_daily/features/tasks/presentation/form/cubit/task_form_cubit.dart';
import 'package:sync_daily/features/tasks/presentation/form/cubit/task_form_state.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ProjectRepository projectRepo;
  var idCounter = 0;

  final fixedNow = DateTime(2026, 10, 14, 8, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = TaskRepositoryImpl(db.tasksDao, db.projectsDao);
    projectRepo = ProjectRepositoryImpl(db.projectsDao);
    idCounter = 0;
  });

  tearDown(() async {
    await db.close();
  });

  TaskFormCubit buildCubit() => TaskFormCubit(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        now: () => fixedNow,
        newId: () => 'id-${idCounter++}',
      );

  Future<TaskFormCubit> startCubit({
    TaskType type = TaskType.task,
    String? taskId,
  }) async {
    final cubit = buildCubit();
    await cubit.init(initialType: type, taskId: taskId);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return cubit;
  }

  group('validasi', () {
    test('judul kosong tidak disimpan dan menampilkan pesan', () async {
      final cubit = await startCubit();
      await cubit.save();

      expect(cubit.state.errorMessage, AppStrings.titleRequired);
      expect(cubit.state.status, isNot(TaskFormStatus.saved));

      final tasks = await taskRepo.watchAllTasks().first;
      expect(tasks, isEmpty);
      await cubit.close();
    });

    test('acara berjam: selesai sebelum mulai ditolak', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Rapat');
      cubit.setStartAt(DateTime(2026, 10, 14, 10));
      cubit.setEndAt(DateTime(2026, 10, 14, 9));

      await cubit.save();

      expect(cubit.state.errorMessage, AppStrings.endBeforeStart);
      final tasks = await taskRepo.watchAllTasks().first;
      expect(tasks, isEmpty);
      await cubit.close();
    });

    test('acara seharian: bandingkan tanggal kalender', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Liburan');
      cubit.setIsAllDay(true);
      cubit.setStartAt(DateTime(2026, 10, 14));
      // 13 Okt < 14 Okt -> tidak valid walaupun jamnya lebih besar.
      cubit.setEndAt(DateTime(2026, 10, 13, 23, 59));

      await cubit.save();
      expect(cubit.state.errorMessage, AppStrings.endBeforeStart);
      await cubit.close();
    });

    test('acara wajib punya waktu mulai', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Rapat');

      await cubit.save();
      expect(cubit.state.errorMessage, AppStrings.startRequired);
      expect(await taskRepo.watchAllTasks().first, isEmpty);
      await cubit.close();
    });

    test('acara berjam wajib punya waktu selesai', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Rapat');
      cubit.setStartAt(DateTime(2026, 10, 14, 9));

      await cubit.save();
      expect(cubit.state.errorMessage, AppStrings.endRequired);
      await cubit.close();
    });

    test('acara seharian boleh tanpa waktu selesai', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Libur');
      cubit.setIsAllDay(true);
      cubit.setStartAt(DateTime(2026, 10, 14));

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.startAt, isNotNull);
      expect(task.endAt, isNull);
      expect(task.isAllDay, isTrue);
      await cubit.close();
    });

    test('pengingat wajib punya waktu', () async {
      final cubit = await startCubit(type: TaskType.reminder);
      cubit.setTitle('Minum obat');

      await cubit.save();
      expect(cubit.state.errorMessage, AppStrings.startRequired);
      await cubit.close();
    });

    test('milestone wajib punya tenggat', () async {
      final cubit = await startCubit(type: TaskType.milestone);
      cubit.setTitle('Rilis');

      await cubit.save();
      expect(cubit.state.errorMessage, AppStrings.dueRequired);
      await cubit.close();
    });

    test('tugas boleh tanpa tanggal', () async {
      final cubit = await startCubit();
      cubit.setTitle('Tanpa tanggal');

      await cubit.save();

      expect(cubit.state.status, TaskFormStatus.saved);
      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.dueAt, isNull);
      await cubit.close();
    });
  });

  group('penyimpanan per tipe', () {
    test('tugas memakai dueAt, start/end kosong', () async {
      final cubit = await startCubit();
      cubit.setTitle('Beli buku');
      cubit.setDueAt(DateTime(2026, 10, 20, 9));

      await cubit.save();

      final tasks = await taskRepo.watchAllTasks().first;
      expect(tasks, hasLength(1));
      final task = tasks.single;
      expect(task.type, TaskType.task);
      expect(task.title, 'Beli buku');
      expect(task.dueAt, isNotNull);
      expect(task.startAt, isNull);
      expect(task.endAt, isNull);
      expect(task.isAllDay, isFalse);
      await cubit.close();
    });

    test('acara memakai startAt dan endAt, dueAt kosong', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Meeting');
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 10));

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.type, TaskType.event);
      expect(task.startAt, isNotNull);
      expect(task.endAt, isNotNull);
      expect(task.dueAt, isNull);
      await cubit.close();
    });

    test('pengingat memakai startAt dan pengingat tepat waktu (offset 0)',
        () async {
      final cubit = await startCubit(type: TaskType.reminder);
      cubit.setTitle('Minum obat');
      cubit.setStartAt(DateTime(2026, 10, 14, 7));

      expect(cubit.state.reminders, contains(ReminderOption.onTime));

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.type, TaskType.reminder);
      expect(task.startAt, isNotNull);
      expect(task.dueAt, isNull);
      expect(task.endAt, isNull);
      expect(task.isAllDay, isFalse);

      final reminders = await taskRepo.getReminders(task.id);
      expect(reminders.map((r) => r.offsetMinutes), [0]);
      await cubit.close();
    });

    test('milestone memakai dueAt dan seharian', () async {
      final cubit = await startCubit(type: TaskType.milestone);
      cubit.setTitle('Rilis 1.0');
      cubit.setDueAt(DateTime(2026, 10, 31));

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.type, TaskType.milestone);
      expect(task.dueAt, isNotNull);
      expect(task.startAt, isNull);
      expect(task.endAt, isNull);
      expect(task.isAllDay, isTrue);
      await cubit.close();
    });

    test('pengulangan dan pengingat hanya tersimpan bila tanggal terisi',
        () async {
      final cubit = await startCubit();
      cubit.setTitle('Tanpa tanggal');
      cubit.setRecurrence(RecurrenceOption.daily);
      cubit.toggleReminder(ReminderOption.tenMinutes);

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(await taskRepo.getRecurrence(task.id), isNull);
      expect(await taskRepo.getReminders(task.id), isEmpty);
      await cubit.close();
    });

    test('pengulangan dan pengingat tersimpan bila tanggal terisi', () async {
      final cubit = await startCubit();
      cubit.setTitle('Dengan tanggal');
      cubit.setDueAt(DateTime(2026, 10, 20));
      cubit.setRecurrence(RecurrenceOption.weekly);
      cubit.toggleReminder(ReminderOption.oneHour);

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      final recurrence = await taskRepo.getRecurrence(task.id);
      expect(recurrence?.frequency, RecurrenceFrequency.weekly);

      final reminders = await taskRepo.getReminders(task.id);
      expect(reminders.map((r) => r.offsetMinutes), [60]);
      await cubit.close();
    });

    test('sub-task hanya pada tipe tugas', () async {
      final cubit = await startCubit();
      cubit.setTitle('Tugas induk');
      cubit.addSubtask('Sub A');
      cubit.addSubtask('Sub B');

      await cubit.save();

      final tasks = await taskRepo.watchAllTasks().first;
      expect(tasks, hasLength(3));
      final parent = tasks.firstWhere((t) => t.parentTaskId == null);
      final subs = tasks.where((t) => t.parentTaskId == parent.id);
      expect(subs.map((t) => t.title), containsAll(['Sub A', 'Sub B']));
      await cubit.close();
    });
  });

  group('aturan tanggal (TaskDateUtils)', () {
    test('seharian tersimpan sebagai tanggal kalender UTC (simulasi WIB)',
        () async {
      // Perangkat WIB: pengguna memilih 14 Okt 2026.
      final cubit = await startCubit(type: TaskType.milestone);
      cubit.setTitle('Rilis');
      cubit.setDueAt(DateTime(2026, 10, 14, 15, 45));

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      // Drift mengembalikan DateTime pada zona yang sama dengan nilai yang
      // ditulis; yang penting instannya = tengah malam UTC tanggal kalender.
      expect(task.dueAt!.toUtc(), DateTime.utc(2026, 10, 14));

      final reference = TaskDateUtils.referenceDate(task)!;
      expect(reference.isUtc, isTrue);
      expect([reference.year, reference.month, reference.day], [2026, 10, 14]);
      expect(TaskDateUtils.isOnDay(task, DateTime(2026, 10, 14)), isTrue);
      await cubit.close();
    });

    test('item berjam disimpan sebagai instan dan dibaca lewat waktu lokal',
        () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Meeting');
      cubit.setStartAt(DateTime(2026, 10, 14, 23, 30));
      cubit.setEndAt(DateTime(2026, 10, 15, 0, 30));

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.startAt!.isAtSameMomentAs(DateTime(2026, 10, 14, 23, 30)), isTrue);
      expect(task.isAllDay, isFalse);

      final reference = TaskDateUtils.referenceDate(task)!;
      expect(reference.isUtc, isFalse);
      expect([reference.year, reference.month, reference.day], [2026, 10, 14]);
      await cubit.close();
    });
  });

  group('mode ubah', () {
    test('memuat data dari repository dan menyimpan perubahan', () async {
      await projectRepo.upsertProject(Project(
        id: 'p1',
        title: 'Proyek A',
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));
      await taskRepo.upsertTask(Task(
        id: 't1',
        projectId: 'p1',
        title: 'Judul lama',
        description: 'Deskripsi lama',
        type: TaskType.task,
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueAt: DateTime(2026, 10, 20, 9),
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));

      final cubit = await startCubit(taskId: 't1');
      expect(cubit.state.isEditing, isTrue);
      expect(cubit.state.title, 'Judul lama');
      expect(cubit.state.description, 'Deskripsi lama');
      expect(cubit.state.priority, TaskPriority.high);
      expect(cubit.state.projectId, 'p1');

      cubit.setTitle('Judul baru');
      await cubit.save(editingTaskId: 't1');

      final tasks = await taskRepo.watchAllTasks().first;
      expect(tasks, hasLength(1));
      final task = tasks.single;
      expect(task.id, 't1');
      expect(task.title, 'Judul baru');
      // Status dan createdAt tidak boleh hilang saat mengubah.
      expect(task.status, TaskStatus.inProgress);
      expect(task.createdAt.toUtc(), fixedNow.toUtc());
      await cubit.close();
    });

    test('memuat sub-task, mengganti nama, dan menghapusnya', () async {
      await taskRepo.upsertTask(Task(
        id: 't1',
        title: 'Induk',
        type: TaskType.task,
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));
      await taskRepo.upsertTask(Task(
        id: 's1',
        parentTaskId: 't1',
        title: 'Sub satu',
        type: TaskType.task,
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));
      await taskRepo.upsertTask(Task(
        id: 's2',
        parentTaskId: 't1',
        title: 'Sub dua',
        type: TaskType.task,
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));

      final cubit = await startCubit(taskId: 't1');
      expect(cubit.state.subtaskTitles, ['Sub satu', 'Sub dua']);

      cubit.updateSubtask(0, 'Sub satu (ubah)');
      cubit.removeSubtask(1);
      cubit.addSubtask('Sub tiga');

      await cubit.save(editingTaskId: 't1');

      final tasks = await taskRepo.watchAllTasks().first;
      final subs = tasks.where((t) => t.parentTaskId == 't1').toList();
      expect(subs.map((t) => t.title), containsAll(['Sub satu (ubah)', 'Sub tiga']));
      expect(subs.map((t) => t.title), isNot(contains('Sub dua')));
      expect(subs, hasLength(2));
      await cubit.close();
    });
  });
}
