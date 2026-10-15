import 'package:flutter/material.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/category_theme.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

/// Label Indonesia untuk pengulangan berdasarkan frekuensi tersimpan.
String recurrenceFrequencyLabel(RecurrenceFrequency frequency) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return AppStrings.daily;
    case RecurrenceFrequency.weekly:
      return AppStrings.weekly;
    case RecurrenceFrequency.monthly:
      return AppStrings.monthly;
    case RecurrenceFrequency.yearly:
      return AppStrings.yearly;
  }
}

/// Label Indonesia untuk offset pengingat (menit sebelum titik acuan).
String reminderOffsetLabel(int offsetMinutes) {
  switch (offsetMinutes) {
    case 0:
      return AppStrings.remindOnTime;
    case 10:
      return AppStrings.remind10Min;
    case 60:
      return AppStrings.remind1Hour;
    case 1440:
      return AppStrings.remind1Day;
    default:
      return AppStrings.remindMinutesBefore(offsetMinutes);
  }
}

/// Label status yang bisa dibaca manusia.
String statusLabel(TaskStatus status) =>
    status == TaskStatus.done ? AppStrings.statusDone : AppStrings.statusNotDone;

/// Judul layar detail sesuai tipe item (kapital di awal tiap kata, EYD).
String taskDetailTitleFor(TaskType type) {
  switch (type) {
    case TaskType.task:
      return AppStrings.detailTask;
    case TaskType.event:
      return AppStrings.detailEvent;
    case TaskType.reminder:
      return AppStrings.detailReminder;
    case TaskType.milestone:
      return AppStrings.detailMilestone;
  }
}

/// Kategori warna untuk sebuah tipe item.
TaskCategory taskCategoryFor(TaskType type) {
  switch (type) {
    case TaskType.task:
      return TaskCategory.task;
    case TaskType.event:
      return TaskCategory.event;
    case TaskType.reminder:
      return TaskCategory.reminder;
    case TaskType.milestone:
      return TaskCategory.milestone;
  }
}

/// Ikon untuk sebuah tipe item (memakai [AppIcons]).
IconData taskIconFor(TaskType type) {
  switch (type) {
    case TaskType.task:
      return AppIcons.check;
    case TaskType.event:
      return AppIcons.calendar;
    case TaskType.reminder:
      return AppIcons.clock;
    case TaskType.milestone:
      return AppIcons.flag;
  }
}
