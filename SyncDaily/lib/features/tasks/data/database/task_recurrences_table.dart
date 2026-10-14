import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/converters/enum_converters.dart';
import 'package:sync_daily/features/tasks/data/database/tasks_table.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Aturan pengulangan (1:1 dengan tugas). `byWeekdays` berupa bitmask.
@DataClassName('TaskRecurrenceRow')
class TaskRecurrences extends Table {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  TextColumn get frequency => textEnum<RecurrenceFrequency>()();

  IntColumn get intervalValue => integer().withDefault(const Constant(1))();
  IntColumn get byWeekdays =>
      integer().map(const WeekdaySetConverter()).nullable()();
  IntColumn get byMonthDay => integer().nullable()();
  DateTimeColumn get untilAt => dateTime().nullable()();
  IntColumn get count => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {taskId};
}
