import 'package:mocktail/mocktail.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/features/auth/domain/entities/user_profile.dart';
import 'package:sync_daily/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockProjectRepository extends Mock implements ProjectRepository {}

class MockNoteRepository extends Mock implements NoteRepository {}

class MockNotificationRepository extends Mock implements NotificationRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

const _emptySummary = TaskSummary(
  today: 0,
  schedule: 0,
  allTasks: 0,
  projectsOwned: 0,
  projectsReceived: 0,
);

/// Mengganti repository berbasis Drift dengan tiruan yang memancarkan data
/// kosong. Dipakai oleh tes widget yang hanya menguji tata letak/navigasi
/// sehingga tidak perlu membuka query stream Drift (yang meninggalkan timer
/// nol-durasi saat dibatalkan di dalam `flutter_test`).
void registerMockRepositories() {
  final taskRepository = MockTaskRepository();
  when(
    () => taskRepository.watchSummary(
      periodStart: any(named: 'periodStart'),
      periodEnd: any(named: 'periodEnd'),
      today: any(named: 'today'),
    ),
  ).thenAnswer((_) => Stream.value(_emptySummary));

  // Dipakai layar Kalender.
  when(() => taskRepository.watchAllTasks())
      .thenAnswer((_) => Stream<List<Task>>.value(const []));
  when(() => taskRepository.watchRecurrences())
      .thenAnswer((_) => Stream<List<TaskRecurrence>>.value(const []));

  final projectRepository = MockProjectRepository();
  when(() => projectRepository.watchProjectsWithCounts())
      .thenAnswer((_) => Stream.value(const []));
  when(() => projectRepository.watchProjects())
      .thenAnswer((_) => Stream.value(const []));

  final notificationRepository = MockNotificationRepository();
  when(() => notificationRepository.watchUnreadCount())
      .thenAnswer((_) => Stream.value(0));

  final userProfileRepository = MockUserProfileRepository();
  when(() => userProfileRepository.watchProfile())
      .thenAnswer((_) => Stream.value(const UserProfile(name: 'Pengguna')));

  // Dipakai layar Catatan (tab keempat). Tanpa tiruan ini, tes tata letak akan
  // membuka query stream Drift yang meninggalkan timer.
  final noteRepository = MockNoteRepository();
  when(() => noteRepository.watchNotes())
      .thenAnswer((_) => Stream<List<Note>>.value(const []));
  when(() => noteRepository.getNote(any())).thenAnswer((_) async => null);

  _override<TaskRepository>(taskRepository);
  _override<ProjectRepository>(projectRepository);
  _override<NotificationRepository>(notificationRepository);
  _override<UserProfileRepository>(userProfileRepository);
  _override<NoteRepository>(noteRepository);
}

void _override<T extends Object>(T instance) {
  if (getIt.isRegistered<T>()) {
    getIt.unregister<T>();
  }
  getIt.registerSingleton<T>(instance);
}
