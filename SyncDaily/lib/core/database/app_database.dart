import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sync_daily/core/database/converters/enum_converters.dart';
import 'package:sync_daily/features/notes/data/database/notes_table.dart';
import 'package:sync_daily/features/notes/data/daos/notes_dao.dart';
import 'package:sync_daily/features/notes/domain/entities/note.dart';
import 'package:sync_daily/features/notifications/data/database/app_notifications_table.dart';
import 'package:sync_daily/features/notifications/data/daos/notifications_dao.dart';
import 'package:sync_daily/features/notifications/domain/entities/app_notification.dart';
import 'package:sync_daily/features/projects/data/database/projects_table.dart';
import 'package:sync_daily/features/projects/data/daos/projects_dao.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/tasks/data/database/task_recurrences_table.dart';
import 'package:sync_daily/features/tasks/data/database/task_reminders_table.dart';
import 'package:sync_daily/features/tasks/data/database/tasks_table.dart';
import 'package:sync_daily/features/tasks/data/daos/tasks_dao.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Projects,
    Tasks,
    TaskReminders,
    TaskRecurrences,
    Notes,
    AppNotifications,
  ],
  daos: [
    ProjectsDao,
    TasksDao,
    NotesDao,
    NotificationsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Constructor menerima [QueryExecutor] agar bisa memakai database
  /// in-memory pada pengujian.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // Migrasi berikutnya: naikkan schemaVersion lalu tambah langkah
        // `if (from < N) { ... }` memakai Migrator. Schema tiap versi
        // diekspor dengan `dart run drift_dev schema dump` ke `drift_schemas/`.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Versi SQLite yang sedang berjalan. Dipakai untuk verifikasi di mode debug.
  Future<String> sqliteVersion() async {
    final row =
        await customSelect('SELECT sqlite_version() AS version').getSingle();
    return row.read<String>('version');
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'sync_daily',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
