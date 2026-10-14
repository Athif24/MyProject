import 'package:sync_daily/features/projects/data/daos/projects_dao.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/tasks/data/daos/tasks_dao.dart';
import 'package:sync_daily/features/tasks/data/mappers/task_mapper.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_summary.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TasksDao _dao;
  final ProjectsDao _projectsDao;

  TaskRepositoryImpl(this._dao, this._projectsDao);

  @override
  Stream<List<Task>> watchTodayTasks() {
    return _dao.watchActiveTasks().map((rows) {
      final today = DateTime.now();
      return rows
          .map((row) => row.toEntity())
          .where((task) =>
              task.status != TaskStatus.done &&
              TaskDateUtils.isOnDay(task, today))
          .toList();
    });
  }

  @override
  Stream<List<Task>> watchTasksInRange(DateTime from, DateTime to) {
    return _dao.watchActiveTasks().map(
          (rows) => rows
              .map((row) => row.toEntity())
              .where((task) => TaskDateUtils.isInRange(task, from, to))
              .toList(),
        );
  }

  @override
  Stream<List<Task>> watchTasksByProject(String projectId) {
    return _dao
        .watchTasksByProject(projectId)
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return _dao
        .watchActiveTasks()
        .map((rows) => rows.map((row) => row.toEntity()).toList());
  }

  @override
  Future<Task?> getTask(String id) async {
    final row = await _dao.getById(id);
    return row?.toEntity();
  }

  @override
  Future<TaskSummary> getSummary({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final rows = await _dao.watchActiveTasks().first;
    final tasks = rows.map((row) => row.toEntity()).toList();
    final today = DateTime.now();

    final period = _weekRange(today);
    final start = periodStart ?? period.start;
    final end = periodEnd ?? period.end;

    final todayCount = tasks
        .where((task) =>
            task.status != TaskStatus.done &&
            TaskDateUtils.isOnDay(task, today))
        .length;

    final scheduleCount = tasks
        .where((task) =>
            (task.type == TaskType.event || task.type == TaskType.reminder) &&
            TaskDateUtils.isInRange(task, start, end))
        .length;

    final allTasksCount = tasks
        .where((task) =>
            (task.type == TaskType.task || task.type == TaskType.milestone) &&
            task.status != TaskStatus.done &&
            task.parentTaskId == null)
        .length;

    final owned = await _projectsDao.countByRole(ProjectRole.owned);
    final received = await _projectsDao.countByRole(ProjectRole.received);

    return TaskSummary(
      today: todayCount,
      schedule: scheduleCount,
      allTasks: allTasksCount,
      projectsOwned: owned,
      projectsReceived: received,
    );
  }

  @override
  Future<void> upsertTask(Task task) => _dao.upsertTask(task.toCompanion());

  @override
  Future<void> setStatus(String id, TaskStatus status) =>
      _dao.setStatus(id, status, DateTime.now().toUtc());

  @override
  Future<void> softDeleteTask(String id) =>
      _dao.softDeleteTaskCascade(id, DateTime.now().toUtc());

  @override
  Future<List<TaskReminder>> getReminders(String taskId) async {
    final rows = await _dao.remindersFor(taskId);
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<void> replaceReminders(
    String taskId,
    List<TaskReminder> reminders,
  ) {
    return _dao.replaceReminders(
      taskId,
      reminders.map((reminder) => reminder.toCompanion()).toList(),
    );
  }

  @override
  Future<TaskRecurrence?> getRecurrence(String taskId) async {
    final row = await _dao.recurrenceFor(taskId);
    return row?.toEntity();
  }

  @override
  Future<void> setRecurrence(String taskId, TaskRecurrence? recurrence) {
    if (recurrence == null) {
      return _dao.deleteRecurrence(taskId);
    }
    return _dao.upsertRecurrence(recurrence.toCompanion());
  }

  /// Rentang minggu berjalan (Senin 00:00 sampai Minggu 23:59:59).
  static ({DateTime start, DateTime end}) _weekRange(DateTime reference) {
    final date = DateTime(reference.year, reference.month, reference.day);
    final start = date.subtract(Duration(days: reference.weekday - 1));
    final end = start
        .add(const Duration(days: 6))
        .add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return (start: start, end: end);
  }
}
