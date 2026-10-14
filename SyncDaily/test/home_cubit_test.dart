import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/features/auth/domain/entities/user_profile.dart';
import 'package:sync_daily/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:sync_daily/features/home/presentation/cubit/home_cubit.dart';
import 'package:sync_daily/features/home/presentation/cubit/home_state.dart';
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

  final summary = const TaskSummary(
    today: 3,
    schedule: 2,
    allTasks: 5,
    projectsOwned: 1,
    projectsReceived: 0,
  );

  final project = ProjectWithCounts(
    project: Project(
      id: 'p1',
      title: 'Proyek',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
    taskCount: 2,
    subtaskCount: 1,
  );

  setUp(() {
    taskRepository = _MockTaskRepository();
    projectRepository = _MockProjectRepository();
    notificationRepository = _MockNotificationRepository();
    userProfileRepository = _MockUserProfileRepository();
  });

  void stubHappyPath({TaskSummary? summaryValue}) {
    when(
      () => taskRepository.watchSummary(
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) => Stream.value(summaryValue ?? summary));
    when(() => projectRepository.watchProjectsWithCounts())
        .thenAnswer((_) => Stream.value([project]));
    when(() => notificationRepository.watchUnreadCount())
        .thenAnswer((_) => Stream.value(4));
    when(() => userProfileRepository.watchProfile())
        .thenAnswer((_) => Stream.value(const UserProfile(name: 'Pengguna')));
  }

  HomeCubit buildCubit() {
    return HomeCubit(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      notificationRepository: notificationRepository,
      userProfileRepository: userProfileRepository,
    );
  }

  blocTest<HomeCubit, HomeState>(
    'memuat ringkasan, proyek, jumlah belum dibaca, dan nama pengguna',
    build: () {
      stubHappyPath();
      return buildCubit()..start();
    },
    wait: const Duration(milliseconds: 50),
    verify: (cubit) {
      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.summary, summary);
      expect(cubit.state.projects, [project]);
      expect(cubit.state.unreadCount, 4);
      expect(cubit.state.userName, 'Pengguna');
    },
  );

  blocTest<HomeCubit, HomeState>(
    'setPeriod memuat ulang ringkasan dengan rentang baru',
    build: () {
      stubHappyPath();
      return buildCubit()..start();
    },
    act: (cubit) => cubit.setPeriod(PeriodFilter.all),
    wait: const Duration(milliseconds: 50),
    verify: (cubit) {
      expect(cubit.state.period, PeriodFilter.all);
      verify(
        () => taskRepository.watchSummary(
          periodStart: null,
          periodEnd: null,
          today: any(named: 'today'),
        ),
      ).called(1);
    },
  );

  blocTest<HomeCubit, HomeState>(
    'error dari stream ringkasan menandai status error',
    build: () {
      when(
        () => taskRepository.watchSummary(
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
          today: any(named: 'today'),
        ),
      ).thenAnswer((_) => Stream<TaskSummary>.error(Exception('gagal')));
      when(() => projectRepository.watchProjectsWithCounts())
          .thenAnswer((_) => const Stream.empty());
      when(() => notificationRepository.watchUnreadCount())
          .thenAnswer((_) => const Stream.empty());
      when(() => userProfileRepository.watchProfile())
          .thenAnswer((_) => const Stream.empty());
      return buildCubit()..start();
    },
    wait: const Duration(milliseconds: 50),
    verify: (cubit) => expect(cubit.state.status, HomeStatus.error),
  );

  test('setProjectTab mengubah tab aktif tanpa mengubah data', () async {
    stubHappyPath();
    final cubit = buildCubit()..start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final before = cubit.state.summary;
    cubit.setProjectTab(ProjectTab.received);

    expect(cubit.state.projectTab, ProjectTab.received);
    expect(cubit.state.summary, before);
    await cubit.close();
  });

  test('sapaan dihitung dari jam yang diinjeksi', () async {
    stubHappyPath();
    final cubit = HomeCubit(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      notificationRepository: notificationRepository,
      userProfileRepository: userProfileRepository,
      now: () => DateTime(2026, 10, 14, 15, 30),
    )..start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.greeting, AppStrings.greetingEvening);
    await cubit.close();
  });

  test('retry() tidak menyisakan langganan ganda', () async {
    final profileController = StreamController<UserProfile>.broadcast();
    final unreadController = StreamController<int>.broadcast();
    final projectsController =
        StreamController<List<ProjectWithCounts>>.broadcast();
    final summaryController = StreamController<TaskSummary>.broadcast();

    var profileEvents = 0;
    var unreadEvents = 0;
    var projectsEvents = 0;
    var summaryEvents = 0;
    var summaryCalls = 0;

    when(() => userProfileRepository.watchProfile()).thenAnswer(
      (_) => profileController.stream.map((event) {
        profileEvents += 1;
        return event;
      }),
    );
    when(() => notificationRepository.watchUnreadCount()).thenAnswer(
      (_) => unreadController.stream.map((event) {
        unreadEvents += 1;
        return event;
      }),
    );
    when(() => projectRepository.watchProjectsWithCounts()).thenAnswer(
      (_) => projectsController.stream.map((event) {
        projectsEvents += 1;
        return event;
      }),
    );
    when(
      () => taskRepository.watchSummary(
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
        today: any(named: 'today'),
      ),
    ).thenAnswer((_) {
      summaryCalls += 1;
      if (summaryCalls == 1) {
        return Stream<TaskSummary>.error(Exception('gagal'));
      }
      return summaryController.stream.map((event) {
        summaryEvents += 1;
        return event;
      });
    });

    final cubit = buildCubit()..start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state.status, HomeStatus.error);

    cubit.retry();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(summaryCalls, 2);

    // Satu event per stream hanya boleh diterima satu langganan.
    profileController.add(const UserProfile(name: 'Pengguna'));
    unreadController.add(4);
    projectsController.add([project]);
    summaryController.add(summary);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(profileEvents, 1);
    expect(unreadEvents, 1);
    expect(projectsEvents, 1);
    expect(summaryEvents, 1);
    expect(cubit.state.status, HomeStatus.loaded);

    await cubit.close();
    expect(profileController.hasListener, isFalse);
    expect(unreadController.hasListener, isFalse);
    expect(projectsController.hasListener, isFalse);
    expect(summaryController.hasListener, isFalse);

    await profileController.close();
    await unreadController.close();
    await projectsController.close();
    await summaryController.close();
  });

  HomeCubit buildCubitAt(DateTime Function() now) {
    return HomeCubit(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      notificationRepository: notificationRepository,
      userProfileRepository: userProfileRepository,
      now: now,
    );
  }

  test('filter Minggu ini memakai jam injeksi: tanggal Minggu → Senin–Minggu',
      () async {
    stubHappyPath();
    // Minggu, 18 Oktober 2026: minggu berjalan Senin 12 – Minggu 18.
    final cubit = buildCubitAt(() => DateTime(2026, 10, 18, 10, 15))..start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    verify(
      () => taskRepository.watchSummary(
        periodStart: DateTime(2026, 10, 12),
        periodEnd: DateTime(2026, 10, 18, 23, 59, 59),
        today: DateTime(2026, 10, 18, 10, 15),
      ),
    ).called(1);

    await cubit.close();
  });

  test('filter Bulan ini memakai jam injeksi: akhir bulan → 1 s.d. akhir bulan',
      () async {
    stubHappyPath();
    // Sabtu, 31 Oktober 2026 (hari terakhir bulan).
    final cubit = buildCubitAt(() => DateTime(2026, 10, 31, 23, 30))..start();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    cubit.setPeriod(PeriodFilter.thisMonth);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    verify(
      () => taskRepository.watchSummary(
        periodStart: DateTime(2026, 10, 1),
        periodEnd: DateTime(2026, 10, 31, 23, 59, 59),
        today: DateTime(2026, 10, 31, 23, 30),
      ),
    ).called(1);

    await cubit.close();
  });
}
