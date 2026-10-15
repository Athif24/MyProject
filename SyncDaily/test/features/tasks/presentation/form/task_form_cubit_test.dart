import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/calendar/domain/calendar_agenda.dart';
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

  group('tanggal awal dari Kalender', () {
    Future<TaskFormCubit> startWithDate({
      TaskType type = TaskType.task,
      DateTime? initialDate,
      String? taskId,
    }) async {
      final cubit = buildCubit();
      await cubit.init(
        initialType: type,
        taskId: taskId,
        initialDate: initialDate,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return cubit;
    }

    test('tugas: tenggat terisi tanggal awal dan sepanjang hari', () async {
      final cubit = await startWithDate(
        initialDate: DateTime(2026, 10, 14, 13, 45),
      );

      expect(cubit.state.dueAt, DateTime(2026, 10, 14));
      expect(cubit.state.isAllDay, isTrue);
      expect(cubit.state.startAt, isNull);

      await cubit.close();
    });

    test('milestone: tenggat terisi dan tetap sepanjang hari', () async {
      final cubit = await startWithDate(
        type: TaskType.milestone,
        initialDate: DateTime(2026, 10, 14),
      );

      expect(cubit.state.dueAt, DateTime(2026, 10, 14));
      expect(cubit.state.isAllDay, isTrue);

      await cubit.close();
    });

    test('acara: mulai 09.00 dan selesai 10.00', () async {
      final cubit = await startWithDate(
        type: TaskType.event,
        initialDate: DateTime(2026, 10, 14),
      );

      expect(cubit.state.startAt, DateTime(2026, 10, 14, 9));
      expect(cubit.state.endAt, DateTime(2026, 10, 14, 10));
      expect(cubit.state.isAllDay, isFalse);
      expect(cubit.state.dueAt, isNull);

      await cubit.close();
    });

    test('pengingat: mulai 09.00 tanpa waktu selesai', () async {
      final cubit = await startWithDate(
        type: TaskType.reminder,
        initialDate: DateTime(2026, 10, 14),
      );

      expect(cubit.state.startAt, DateTime(2026, 10, 14, 9));
      expect(cubit.state.endAt, isNull);
      expect(cubit.state.isAllDay, isFalse);

      await cubit.close();
    });

    test('tanpa tanggal awal, kolom tanggal tetap kosong', () async {
      final cubit = await startWithDate();

      expect(cubit.state.dueAt, isNull);
      expect(cubit.state.startAt, isNull);
      expect(cubit.state.isAllDay, isFalse);

      await cubit.close();
    });

    test('tanpa tanggal awal, ganti tipe tidak mengisi kolom tanggal',
        () async {
      final cubit = await startWithDate();

      cubit.setType(TaskType.event);
      expect(cubit.state.startAt, isNull);
      expect(cubit.state.endAt, isNull);

      cubit.setType(TaskType.milestone);
      expect(cubit.state.dueAt, isNull);

      await cubit.close();
    });

    test('ganti tipe memperbarui bawaan tanggal (tidak menyisakan 00.00)',
        () async {
      final cubit = await startWithDate(
        initialDate: DateTime(2026, 10, 14),
      );
      expect(cubit.state.dueAt, DateTime(2026, 10, 14));
      expect(cubit.state.isAllDay, isTrue);

      cubit.setType(TaskType.event);
      expect(cubit.state.startAt, DateTime(2026, 10, 14, 9));
      expect(cubit.state.endAt, DateTime(2026, 10, 14, 10));

      cubit.setType(TaskType.reminder);
      expect(cubit.state.startAt, DateTime(2026, 10, 14, 9));
      expect(cubit.state.endAt, isNull);

      cubit.setType(TaskType.milestone);
      expect(cubit.state.dueAt, DateTime(2026, 10, 14));
      expect(cubit.state.isAllDay, isTrue);
      expect(cubit.state.startAt, isNull);

      cubit.setType(TaskType.task);
      expect(cubit.state.dueAt, DateTime(2026, 10, 14));
      expect(cubit.state.isAllDay, isTrue);

      await cubit.close();
    });

    test('ganti tipe dari ?date= tersimpan berjam sesuai tipe baru', () async {
      final cubit = await startWithDate(
        initialDate: DateTime(2026, 10, 14),
      );
      cubit.setTitle('Rapat');
      cubit.setType(TaskType.event);

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.type, TaskType.event);
      expect(task.isAllDay, isFalse);
      expect(task.startAt!.isAtSameMomentAs(DateTime(2026, 10, 14, 9)), isTrue);
      expect(task.endAt!.isAtSameMomentAs(DateTime(2026, 10, 14, 10)), isTrue);
      await cubit.close();
    });

    test('tugas dari ?date= tersimpan seharian sebagai tanggal kalender UTC',
        () async {
      // Simulasi perangkat WIB: pengguna menekan tombol tambah Kalender.
      final cubit = await startWithDate(
        initialDate: DateTime(2026, 10, 14, 13, 45),
      );
      cubit.setTitle('Beli buku');

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.isAllDay, isTrue);
      expect(task.dueAt!.toUtc(), DateTime.utc(2026, 10, 14));
      expect(TaskDateUtils.isOnDay(task, DateTime(2026, 10, 14)), isTrue);
      await cubit.close();
    });

    test('tugas dari ?date= tampil sepanjang hari di agenda', () async {
      final cubit = await startWithDate(
        initialDate: DateTime(2026, 10, 14, 13, 45),
      );
      cubit.setTitle('Beli buku');

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      final entries = CalendarAgenda.entriesOnDay(
        tasks: [task],
        recurrences: const [],
        day: DateTime(2026, 10, 14),
      );

      expect(entries, hasLength(1));
      expect(entries.single.timeKind, CalendarTimeKind.allDay);
      expect(entries.single.time, isNull);
      await cubit.close();
    });

    test('acara dari ?date= tersimpan berjam 09.00 sampai 10.00', () async {
      final cubit = await startWithDate(
        type: TaskType.event,
        initialDate: DateTime(2026, 10, 14),
      );
      cubit.setTitle('Rapat');

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.isAllDay, isFalse);
      expect(task.startAt!.isAtSameMomentAs(DateTime(2026, 10, 14, 9)), isTrue);
      expect(task.endAt!.isAtSameMomentAs(DateTime(2026, 10, 14, 10)), isTrue);
      expect(task.dueAt, isNull);
      await cubit.close();
    });

    test('pengingat dari ?date= tersimpan berjam 09.00', () async {
      final cubit = await startWithDate(
        type: TaskType.reminder,
        initialDate: DateTime(2026, 10, 14),
      );
      cubit.setTitle('Minum obat');

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.startAt!.isAtSameMomentAs(DateTime(2026, 10, 14, 9)), isTrue);
      expect(task.endAt, isNull);
      expect(task.isAllDay, isFalse);
      await cubit.close();
    });

    test('tanggal awal tidak menimpa data pada mode ubah', () async {
      await taskRepo.upsertTask(Task(
        id: 't1',
        title: 'Lama',
        type: TaskType.task,
        dueAt: DateTime(2026, 10, 20, 9),
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));

      final cubit = await startWithDate(
        taskId: 't1',
        initialDate: DateTime(2026, 10, 14),
      );

      expect(cubit.state.dueAt, DateTime(2026, 10, 20, 9));
      expect(cubit.state.isAllDay, isFalse);

      // Ganti tipe pada mode ubah juga tidak memakai tanggal awal Kalender.
      cubit.setType(TaskType.event);
      expect(cubit.state.startAt, isNull);
      expect(cubit.state.endAt, isNull);
      expect(cubit.state.dueAt, isNull);

      await cubit.close();
    });

    test('milestone dengan tanggal awal disimpan sebagai UTC tengah malam',
        () async {
      final cubit = await startWithDate(
        type: TaskType.milestone,
        initialDate: DateTime(2026, 10, 14),
      );
      cubit.setTitle('Target');

      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.dueAt!.toUtc(), DateTime.utc(2026, 10, 14));
      expect(TaskDateUtils.isOnDay(task, DateTime(2026, 10, 14)), isTrue);

      await cubit.close();
    });
  });

  group('acara: Selesai ikut bergeser saat Mulai diubah', () {
    test('ubah tanggal Mulai: durasi tetap', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 10, 30));

      // Pengguna memilih tanggal Mulai lain (jamnya tetap 09.00, WIB).
      cubit.setStartAt(DateTime(2026, 10, 16, 9));

      expect(cubit.state.startAt, DateTime(2026, 10, 16, 9));
      expect(cubit.state.endAt, DateTime(2026, 10, 16, 10, 30));

      cubit.setTitle('Rapat');
      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.startAt!.isAtSameMomentAs(DateTime(2026, 10, 16, 9)), isTrue);
      expect(
        task.endAt!.isAtSameMomentAs(DateTime(2026, 10, 16, 10, 30)),
        isTrue,
      );
      await cubit.close();
    });

    test('ubah jam Mulai: durasi tetap', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 10, 30));

      cubit.setStartAt(DateTime(2026, 10, 14, 14, 15));

      expect(cubit.state.endAt, DateTime(2026, 10, 14, 15, 45));
      await cubit.close();
    });

    test('durasi lintas tengah malam tetap saat Mulai digeser', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setStartAt(DateTime(2026, 10, 14, 23));
      cubit.setEndAt(DateTime(2026, 10, 15, 1));

      cubit.setStartAt(DateTime(2026, 10, 20, 23));

      expect(cubit.state.startAt, DateTime(2026, 10, 20, 23));
      expect(cubit.state.endAt, DateTime(2026, 10, 21, 1));
      await cubit.close();
    });

    test('acara seharian: selisih hari tetap dan tersimpan sebagai tanggal '
        'kalender UTC', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setIsAllDay(true);
      cubit.setStartAt(DateTime(2026, 10, 14));
      cubit.setEndAt(DateTime(2026, 10, 16));

      cubit.setStartAt(DateTime(2026, 10, 20));

      expect(cubit.state.startAt, DateTime(2026, 10, 20));
      expect(cubit.state.endAt, DateTime(2026, 10, 22));

      cubit.setTitle('Liburan');
      await cubit.save();

      final task = (await taskRepo.watchAllTasks().first).single;
      expect(task.isAllDay, isTrue);
      expect(task.startAt!.toUtc(), DateTime.utc(2026, 10, 20));
      expect(task.endAt!.toUtc(), DateTime.utc(2026, 10, 22));
      expect(TaskDateUtils.isOnDay(task, DateTime(2026, 10, 20)), isTrue);
      await cubit.close();
    });

    test('mode ubah acara berjam: dimuat apa adanya, lalu ikut bergeser',
        () async {
      await taskRepo.upsertTask(Task(
        id: 'e1',
        title: 'Rapat',
        type: TaskType.event,
        startAt: DateTime(2026, 10, 14, 9),
        endAt: DateTime(2026, 10, 14, 10),
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));

      final cubit = await startCubit(taskId: 'e1');

      // Dimuat TIDAK menggeser Selesai.
      expect(cubit.state.startAt, DateTime(2026, 10, 14, 9));
      expect(cubit.state.endAt, DateTime(2026, 10, 14, 10));

      cubit.setStartAt(DateTime(2026, 10, 17, 8));

      expect(cubit.state.endAt, DateTime(2026, 10, 17, 9));

      await cubit.save(editingTaskId: 'e1');
      final task = await taskRepo.getTask('e1');
      expect(task!.endAt!.isAtSameMomentAs(DateTime(2026, 10, 17, 9)), isTrue);
      await cubit.close();
    });

    test('mode ubah acara seharian: dimuat apa adanya, lalu ikut bergeser '
        '(simulasi WIB)', () async {
      // Data tersimpan sebagai tanggal kalender UTC.
      await taskRepo.upsertTask(Task(
        id: 'e1',
        title: 'Liburan',
        type: TaskType.event,
        isAllDay: true,
        startAt: DateTime.utc(2026, 10, 14),
        endAt: DateTime.utc(2026, 10, 16),
        createdAt: fixedNow.toUtc(),
        updatedAt: fixedNow.toUtc(),
      ));

      final cubit = await startCubit(taskId: 'e1');

      // Dimuat TIDAK menggeser Selesai (tanggal kalender tetap).
      expect(_calendarFields(cubit.state.startAt!), [2026, 10, 14]);
      expect(_calendarFields(cubit.state.endAt!), [2026, 10, 16]);

      cubit.setStartAt(DateTime(2026, 10, 20));

      expect(_calendarFields(cubit.state.startAt!), [2026, 10, 20]);
      expect(_calendarFields(cubit.state.endAt!), [2026, 10, 22]);

      await cubit.save(editingTaskId: 'e1');
      final task = await taskRepo.getTask('e1');
      expect(task!.endAt!.toUtc(), DateTime.utc(2026, 10, 22));
      await cubit.close();
    });

    test('Selesai kosong: mengubah Mulai tidak menggeser apa pun', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setStartAt(DateTime(2026, 10, 14, 9));

      cubit.setStartAt(DateTime(2026, 10, 20, 14));
      expect(cubit.state.startAt, DateTime(2026, 10, 20, 14));
      expect(cubit.state.endAt, isNull);

      // Sama untuk acara seharian.
      cubit.setIsAllDay(true);
      cubit.setStartAt(DateTime(2026, 10, 22));
      expect(cubit.state.startAt, DateTime(2026, 10, 22));
      expect(cubit.state.endAt, isNull);
      await cubit.close();
    });

    test('mengubah Selesai tidak menggeser Mulai', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 10));

      cubit.setEndAt(DateTime(2026, 10, 18, 15));

      expect(cubit.state.startAt, DateTime(2026, 10, 14, 9));
      expect(cubit.state.endAt, DateTime(2026, 10, 18, 15));
      await cubit.close();
    });

    test('mengganti tipe tidak menggeser Selesai', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 17));

      cubit.setType(TaskType.event);

      expect(cubit.state.endAt, DateTime(2026, 10, 14, 17));
      await cubit.close();
    });

    test('menyimpan setelah mengubah Mulai tidak memunculkan galat urutan '
        'waktu', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Rapat');
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 10));

      // Geser Mulai ke hari berikutnya tanpa menyentuh Selesai.
      cubit.setStartAt(DateTime(2026, 10, 15, 9));

      await cubit.save();

      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.status, TaskFormStatus.saved);
      await cubit.close();
    });

    test('Selesai tetap tidak valid bila pengguna sengaja membuatnya lebih '
        'awal', () async {
      final cubit = await startCubit(type: TaskType.event);
      cubit.setTitle('Rapat');
      cubit.setStartAt(DateTime(2026, 10, 14, 9));
      cubit.setEndAt(DateTime(2026, 10, 14, 10));

      // Mengubah Selesai (bukan Mulai) tetap divalidasi seperti semula.
      cubit.setEndAt(DateTime(2026, 10, 14, 8));

      await cubit.save();
      expect(cubit.state.errorMessage, AppStrings.endBeforeStart);
      await cubit.close();
    });
  });
}

/// Komponen tanggal kalender (tahun, bulan, hari) dari sebuah waktu.
List<int> _calendarFields(DateTime value) => [value.year, value.month, value.day];
