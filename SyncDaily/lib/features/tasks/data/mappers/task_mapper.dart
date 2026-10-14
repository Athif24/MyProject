import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';

extension TaskRowMapper on TaskRow {
  Task toEntity() => Task(
        id: id,
        projectId: projectId,
        parentTaskId: parentTaskId,
        title: title,
        description: description,
        type: type,
        status: status,
        priority: priority,
        startAt: startAt,
        endAt: endAt,
        dueAt: dueAt,
        isAllDay: isAllDay,
        completedAt: completedAt,
        remoteId: remoteId,
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension TaskEntityMapper on Task {
  TasksCompanion toCompanion() => TasksCompanion(
        id: Value(id),
        projectId: Value(projectId),
        parentTaskId: Value(parentTaskId),
        title: Value(title),
        description: Value(description),
        type: Value(type),
        status: Value(status),
        priority: Value(priority),
        startAt: Value(startAt),
        endAt: Value(endAt),
        dueAt: Value(dueAt),
        isAllDay: Value(isAllDay),
        completedAt: Value(completedAt),
        remoteId: Value(remoteId),
        version: Value(version),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}

extension TaskReminderRowMapper on TaskReminderRow {
  TaskReminder toEntity() => TaskReminder(
        id: id,
        taskId: taskId,
        offsetMinutes: offsetMinutes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension TaskReminderEntityMapper on TaskReminder {
  TaskRemindersCompanion toCompanion() => TaskRemindersCompanion(
        id: Value(id),
        taskId: Value(taskId),
        offsetMinutes: Value(offsetMinutes),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension TaskRecurrenceRowMapper on TaskRecurrenceRow {
  TaskRecurrence toEntity() => TaskRecurrence(
        taskId: taskId,
        frequency: frequency,
        intervalValue: intervalValue,
        byWeekdays: byWeekdays,
        byMonthDay: byMonthDay,
        untilAt: untilAt,
        count: count,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension TaskRecurrenceEntityMapper on TaskRecurrence {
  TaskRecurrencesCompanion toCompanion() => TaskRecurrencesCompanion(
        taskId: Value(taskId),
        frequency: Value(frequency),
        intervalValue: Value(intervalValue),
        byWeekdays: Value(byWeekdays),
        byMonthDay: Value(byMonthDay),
        untilAt: Value(untilAt),
        count: Value(count),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}
