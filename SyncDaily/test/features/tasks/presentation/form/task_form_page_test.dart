import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/main.dart';

import '../../../../helpers/test_dependencies.dart';
import '../../../../helpers/test_repositories.dart';

/// Tes widget form: dibuka dari tombol + nav, diisi, lalu disimpan.
///
/// Memakai repository tiruan (bukan Drift), mengikuti pola tes widget lain di
/// proyek ini: query stream Drift meninggalkan timer saat dibatalkan di dalam
/// `flutter_test` (lihat catatan di `test/helpers/test_repositories.dart`).
void main() {
  late AppDatabase db;
  late MockTaskRepository taskRepository;
  late MockProjectRepository projectRepository;

  setUpAll(() async {
    await IdDate.ensureInitialized();
    registerFallbackValue(Task(
      id: 'fallback',
      title: 'fallback',
      type: TaskType.task,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ));
    registerFallbackValue(<TaskReminder>[]);
  });

  setUp(() async {
    db = await setUpInMemoryDependencies();
    registerMockRepositories();

    taskRepository = MockTaskRepository();
    projectRepository = MockProjectRepository();

    when(
      () => taskRepository.watchSummary(
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
        today: any(named: 'today'),
      ),
    ).thenAnswer(
      (_) => Stream.value(
        const TaskSummary(
          today: 0,
          schedule: 0,
          allTasks: 0,
          projectsOwned: 0,
          projectsReceived: 0,
        ),
      ),
    );
    when(
      () => taskRepository.watchAllTasks(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => taskRepository.upsertTask(any()),
    ).thenAnswer((_) async {});
    when(
      () => taskRepository.replaceReminders(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => taskRepository.setRecurrence(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => projectRepository.watchProjects(),
    ).thenAnswer((_) => Stream.value(const []));
    when(
      () => projectRepository.watchProjectsWithCounts(),
    ).thenAnswer((_) => Stream.value(const []));

    getIt.unregister<TaskRepository>();
    getIt.registerSingleton<TaskRepository>(taskRepository);
    getIt.unregister<ProjectRepository>();
    getIt.registerSingleton<ProjectRepository>(projectRepository);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  testWidgets('form dibuka dari tombol +, diisi, lalu disimpan',
      (tester) async {
    await tester.pumpWidget(const SyncDailyApp());
    await tester.pumpAndSettle();

    // Tombol + di nav membuka form.
    await tester.tap(find.byIcon(AppIcons.add));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.newItem), findsOneWidget);

    // Simpan tanpa judul ditolak: pesan muncul dan tetap di form.
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.titleRequired), findsOneWidget);
    verifyNever(() => taskRepository.upsertTask(any()));

    // Isi judul (field teks pertama), lalu simpan.
    await tester.enterText(find.byType(TextField).first, 'Rapat tim');
    await tester.pump();
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    // Form tertutup dan item dikirim ke repository.
    expect(find.text(AppStrings.newItem), findsNothing);
    final captured = verify(
      () => taskRepository.upsertTask(captureAny()),
    ).captured;
    expect(captured, hasLength(1));
    final saved = captured.single as Task;
    expect(saved.title, 'Rapat tim');
    expect(saved.type, TaskType.task);
  });
}
