import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/converters/enum_converters.dart';
import 'package:sync_daily/features/projects/data/database/projects_table.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Tabel tugas/acara/pengingat/milestone. Waktu disimpan UTC.
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();

  /// Null berarti tugas pribadi (tidak terikat proyek).
  TextColumn get projectId =>
      text().nullable().references(Projects, #id)();

  /// Menunjuk tugas induk untuk sub-task.
  TextColumn get parentTaskId =>
      text().nullable().references(Tasks, #id)();

  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get type => textEnum<TaskType>()();
  TextColumn get status => text().map(const TaskStatusConverter())();
  TextColumn get priority => textEnum<TaskPriority>()();

  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();

  /// Item sepanjang hari: tanggal kalender disimpan sebagai UTC tengah malam
  /// dan ditampilkan tanpa konversi zona waktu.
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();

  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get remoteId => text().nullable().unique()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
