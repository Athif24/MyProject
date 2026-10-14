import 'package:drift/drift.dart';
import 'package:sync_daily/features/notifications/domain/entities/app_notification.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Menyimpan [TaskStatus] sebagai token API (`todo`, `in_progress`, `done`)
/// supaya cocok dengan kontrak BackEnd.
class TaskStatusConverter extends TypeConverter<TaskStatus, String> {
  const TaskStatusConverter();

  @override
  TaskStatus fromSql(String fromDb) => TaskStatus.fromApiValue(fromDb);

  @override
  String toSql(TaskStatus value) => value.apiValue;
}

/// Menyimpan [NotificationType] sebagai token API (snake_case).
class NotificationTypeConverter extends TypeConverter<NotificationType, String> {
  const NotificationTypeConverter();

  @override
  NotificationType fromSql(String fromDb) =>
      NotificationType.fromApiValue(fromDb);

  @override
  String toSql(NotificationType value) => value.apiValue;
}

/// Menyimpan himpunan hari sebagai bitmask integer (bit 0 = Senin).
/// Menghindari penyimpanan teks yang dipisah koma.
class WeekdaySetConverter extends TypeConverter<Set<Weekday>, int> {
  const WeekdaySetConverter();

  @override
  Set<Weekday> fromSql(int fromDb) => {
        for (final day in Weekday.values)
          if (fromDb & (1 << day.index) != 0) day,
      };

  @override
  int toSql(Set<Weekday> value) =>
      value.fold(0, (mask, day) => mask | (1 << day.index));
}
