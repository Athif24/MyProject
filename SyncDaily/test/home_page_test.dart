import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_theme.dart';
import 'package:sync_daily/core/utils/greeting.dart';
import 'package:sync_daily/core/utils/id_date.dart';
import 'package:sync_daily/core/widgets/unread_badge.dart';
import 'package:sync_daily/features/auth/domain/entities/user_profile.dart';
import 'package:sync_daily/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:sync_daily/features/home/presentation/cubit/home_state.dart';
import 'package:sync_daily/features/home/presentation/pages/home_page.dart';
import 'package:sync_daily/features/home/presentation/widgets/stat_card.dart';
import 'package:sync_daily/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/entities/project_with_counts.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _MockProjectRepository extends Mock implements ProjectRepository {}

class _MockNotificationRepository extends Mock implements NotificationRepository {}

class _MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late _MockTaskRepository taskRepository;
  late _MockProjectRepository projectRepository;
  late _MockNotificationRepository notificationRepository;
  late _MockUserProfileRepository userProfileRepository;

  const summary = TaskSummary(
    today: 3,
    schedule: 2,
    allTasks: 5,
    projectsOwned: 1,
    projectsReceived: 0,
  );

  final project = ProjectWithCounts(
    project: Project(
      id: 'p1',
      title: 'Proyek A',
      role: ProjectRole.owned,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
    taskCount: 1,
    subtaskCount: 1,
  );

  setUpAll(() async {
    await IdDate.ensureInitialized();
  });

  void stubHappyPath() {
    when(
      () => taskRepository.watchSummary(
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) => Stream.value(summary));
    when(() => projectRepository.watchProjectsWithCounts())
        .thenAnswer((_) => Stream.value([project]));
    when(() => notificationRepository.watchUnreadCount())
        .thenAnswer((_) => Stream.value(3));
    when(() => userProfileRepository.watchProfile())
        .thenAnswer((_) => Stream.value(const UserProfile(name: 'Pengguna')));
  }

  setUp(() async {
    taskRepository = _MockTaskRepository();
    projectRepository = _MockProjectRepository();
    notificationRepository = _MockNotificationRepository();
    userProfileRepository = _MockUserProfileRepository();

    stubHappyPath();

    await getIt.reset();
    getIt.registerSingleton<TaskRepository>(taskRepository);
    getIt.registerSingleton<ProjectRepository>(projectRepository);
    getIt.registerSingleton<NotificationRepository>(notificationRepository);
    getIt.registerSingleton<UserProfileRepository>(userProfileRepository);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2700);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const HomePage()),
    );
    await tester.pumpAndSettle();
  }

  Map<String, int> statValues(WidgetTester tester) {
    final cards = tester.widgetList<StatCard>(find.byType(StatCard));
    return {for (final card in cards) card.label: card.value};
  }

  testWidgets('menampilkan angka dan daftar proyek dari data',
      (tester) async {
    await pumpHome(tester);

    expect(find.text(Greeting.forTime(DateTime.now())), findsOneWidget);
    expect(find.text('Pengguna'), findsOneWidget);
    expect(find.text('Proyek A'), findsOneWidget);
    expect(find.text('1 Task'), findsOneWidget);
    expect(find.text('1 Sub-task'), findsOneWidget);

    final stats = statValues(tester);
    expect(stats['Hari ini'], 3);
    expect(stats['Jadwal'], 2);
    expect(stats['Proyek'], 1);
    expect(stats['Semua tugas'], 5);

    final badge = tester.widget<UnreadBadge>(find.byType(UnreadBadge));
    expect(badge.count, 3);
  });

  testWidgets('menampilkan empty state saat belum ada proyek', (tester) async {
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
    when(() => projectRepository.watchProjectsWithCounts())
        .thenAnswer((_) => Stream.value(const []));
    when(() => notificationRepository.watchUnreadCount())
        .thenAnswer((_) => Stream.value(0));

    await pumpHome(tester);

    expect(find.text('Belum ada proyek'), findsOneWidget);
    expect(find.byType(UnreadBadge), findsNothing);

    final stats = statValues(tester);
    expect(stats.values.every((value) => value == 0), isTrue);
  });

  testWidgets('menampilkan keadaan error saat repository gagal',
      (tester) async {
    when(
      () => taskRepository.watchSummary(
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) => Stream<TaskSummary>.error(Exception('gagal')));

    await pumpHome(tester);

    expect(find.text('Gagal memuat data'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('tab Diterima menampilkan empty state setelah tersinkronisasi',
      (tester) async {
    // Hanya ada proyek milik sendiri, jadi tab Diterima kosong.
    await pumpHome(tester);

    final tab = find.text(
      AppStrings.tabWithCount(ProjectTab.received.label, 0),
    );
    expect(tab, findsOneWidget);

    await tester.ensureVisible(tab);
    await tester.pumpAndSettle();
    await tester.tap(tab);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noReceivedProjects), findsOneWidget);
    expect(
      find.text(AppStrings.noReceivedProjectsDescription),
      findsOneWidget,
    );
  });
}
