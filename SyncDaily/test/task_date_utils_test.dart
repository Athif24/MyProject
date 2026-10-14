import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';
import 'package:sync_daily/features/tasks/domain/task_date_utils.dart';

void main() {
  Task task({
    DateTime? startAt,
    DateTime? dueAt,
    bool isAllDay = false,
  }) {
    final ts = DateTime.utc(2026, 1, 1);
    return Task(
      id: 't',
      title: 'Tugas',
      type: TaskType.task,
      startAt: startAt,
      dueAt: dueAt,
      isAllDay: isAllDay,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  TaskReminder reminder(int offset) {
    final ts = DateTime.utc(2026, 1, 1);
    return TaskReminder(
      id: 'r',
      taskId: 't',
      offsetMinutes: offset,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  test('titik acuan pengingat memakai startAt bila ada', () {
    final t = task(
      startAt: DateTime.utc(2026, 10, 1, 9),
      dueAt: DateTime.utc(2026, 10, 1, 17),
    );
    expect(
      TaskDateUtils.reminderTimeFor(t, reminder(30)),
      DateTime.utc(2026, 10, 1, 8, 30),
    );
  });

  test('titik acuan pengingat memakai dueAt bila startAt kosong', () {
    final t = task(dueAt: DateTime.utc(2026, 10, 1, 17));
    expect(
      TaskDateUtils.reminderTimeFor(t, reminder(60)),
      DateTime.utc(2026, 10, 1, 16),
    );
  });

  test('offset 0 untuk reminder memakai waktu tugas itu sendiri', () {
    final t = task(startAt: DateTime.utc(2026, 10, 1, 7));
    expect(
      TaskDateUtils.reminderTimeFor(t, reminder(0)),
      DateTime.utc(2026, 10, 1, 7),
    );
  });

  test('item all-day tidak bergeser sehari', () {
    final t = task(isAllDay: true, dueAt: DateTime.utc(2026, 10, 14));
    expect(TaskDateUtils.isOnDay(t, DateTime(2026, 10, 14)), isTrue);
    expect(TaskDateUtils.isOnDay(t, DateTime(2026, 10, 15)), isFalse);
  });
}
