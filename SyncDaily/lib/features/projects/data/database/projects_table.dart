import 'package:drift/drift.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';

@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get role => textEnum<ProjectRole>().nullable()();
  TextColumn get remoteId => text().nullable().unique()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
