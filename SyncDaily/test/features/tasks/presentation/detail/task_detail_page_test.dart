import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/presentation/detail/pages/task_detail_page.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_labels.dart';

import '../../../../helpers/test_repositories.dart';

/// Judul layar detail mengikuti tipe item (kapital di awal tiap kata, EYD).
void main() {
  late MockTaskRepository taskRepository;

  setUpAll(() async {
    await IdDate.ensureInitialized();
  });

  setUp(() {
    registerMockRepositories();
    taskRepository = MockTaskRepository();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpDetail(WidgetTester tester, TaskType type) async {
    final now = DateTime.now();
    final task = Task(
      id: 't1',
      title: 'Item',
      type: type,
      dueAt: now,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
    );
    when(() => taskRepository.watchAllTasks())
        .thenAnswer((_) => Stream.value([task]));
    when(() => taskRepository.getReminders(any()))
        .thenAnswer((_) async => []);
    when(() => taskRepository.getRecurrence(any()))
        .thenAnswer((_) async => null);

    getIt.unregister<TaskRepository>();
    getIt.registerSingleton<TaskRepository>(taskRepository);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const TaskDetailPage(taskId: 't1'),
      ),
    );
    await tester.pumpAndSettle();
  }

  final cases = <TaskType, String>{
    TaskType.task: AppStrings.detailTask,
    TaskType.event: AppStrings.detailEvent,
    TaskType.reminder: AppStrings.detailReminder,
    TaskType.milestone: AppStrings.detailMilestone,
  };

  for (final entry in cases.entries) {
    testWidgets('judul detail untuk tipe ${entry.key.name}', (tester) async {
      await pumpDetail(tester, entry.key);

      expect(find.text(entry.value), findsOneWidget);
      expect(taskDetailTitleFor(entry.key), entry.value);
    });
  }
}
