import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notes/data/repositories/note_repository_impl.dart';
import 'package:sync_daily/features/notes/domain/repositories/note_repository.dart';
import 'package:sync_daily/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:sync_daily/features/notifications/domain/repositories/notification_repository.dart';
import 'package:sync_daily/features/projects/data/repositories/project_repository_impl.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';

final getIt = GetIt.instance;

/// Daftarkan dependency di sini secara manual (mis. repository, bloc/cubit,
/// service) saat fiturnya dikerjakan.
Future<void> configureDependencies() async {
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(database.tasksDao, database.projectsDao),
  );
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(database.projectsDao),
  );
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(database.notesDao),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(database.notificationsDao),
  );

  if (kDebugMode) {
    final version = await database.sqliteVersion();
    debugPrint('[SyncDaily] SQLite $version siap di perangkat.');
  }
}
