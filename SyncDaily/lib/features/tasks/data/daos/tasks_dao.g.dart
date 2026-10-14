// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_dao.dart';

// ignore_for_file: type=lint
mixin _$TasksDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  $TaskRemindersTable get taskReminders => attachedDatabase.taskReminders;
  $TaskRecurrencesTable get taskRecurrences => attachedDatabase.taskRecurrences;
  TasksDaoManager get managers => TasksDaoManager(this);
}

class TasksDaoManager {
  final _$TasksDaoMixin _db;
  TasksDaoManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$TaskRemindersTableTableManager get taskReminders =>
      $$TaskRemindersTableTableManager(_db.attachedDatabase, _db.taskReminders);
  $$TaskRecurrencesTableTableManager get taskRecurrences =>
      $$TaskRecurrencesTableTableManager(
        _db.attachedDatabase,
        _db.taskRecurrences,
      );
}
