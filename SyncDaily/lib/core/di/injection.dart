import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/state/calendar_selection.dart';
import 'package:sync_daily/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:sync_daily/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:sync_daily/features/debug/data/debug_data_seeder.dart';
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
///
/// [database] bisa diisi saat pengujian (mis. database in-memory). Bila null,
/// database utama perangkat yang dipakai.
Future<void> configureDependencies({AppDatabase? database}) async {
  final db = database ?? AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(db.tasksDao, db.projectsDao),
  );
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(db.projectsDao),
  );
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(db.notesDao),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(db.notificationsDao),
  );
  getIt.registerLazySingleton<UserProfileRepository>(
    UserProfileRepositoryImpl.new,
  );

  // Keadaan sesi layar (bukan data): tanggal terpilih di Kalender untuk panel
  // "Buat Baru". Lihat [CalendarSelection].
  getIt.registerLazySingleton<CalendarSelection>(CalendarSelection.new);

  if (kDebugMode) {
    getIt.registerLazySingleton<DebugDataSeeder>(
      () => DebugDataSeeder(
        database: db,
        taskRepository: getIt<TaskRepository>(),
        projectRepository: getIt<ProjectRepository>(),
        notificationRepository: getIt<NotificationRepository>(),
      ),
    );

    final version = await db.sqliteVersion();
    debugPrint('[SyncDaily] SQLite $version siap di perangkat.');
  }
}
