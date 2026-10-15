import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';

enum TaskFormStatus { idle, saving, saved, error }

/// Pilihan pengingat. [onTime] (0 menit) hanya untuk tipe Pengingat: waktunya
/// sendiri adalah titik acuan.
enum ReminderOption { onTime, tenMinutes, oneHour, oneDay }

extension ReminderOptionX on ReminderOption {
  int toOffsetMinutes() {
    switch (this) {
      case ReminderOption.onTime:
        return 0;
      case ReminderOption.tenMinutes:
        return 10;
      case ReminderOption.oneHour:
        return 60;
      case ReminderOption.oneDay:
        return 1440;
    }
  }
}

enum RecurrenceOption { none, daily, weekly, monthly }

extension RecurrenceOptionX on RecurrenceOption {
  RecurrenceFrequency? toFrequency() {
    switch (this) {
      case RecurrenceOption.none:
        return null;
      case RecurrenceOption.daily:
        return RecurrenceFrequency.daily;
      case RecurrenceOption.weekly:
        return RecurrenceFrequency.weekly;
      case RecurrenceOption.monthly:
        return RecurrenceFrequency.monthly;
    }
  }
}

class TaskFormState extends Equatable {
  final TaskFormStatus status;
  final bool isEditing;
  final TaskType type;
  final String title;
  final String description;
  final TaskPriority priority;
  final String? projectId;
  final List<String> subtaskTitles;
  final RecurrenceOption recurrence;
  final Set<ReminderOption> reminders;
  final bool isAllDay;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? dueAt;
  final List<Project> projects;
  final String? errorMessage;

  const TaskFormState({
    this.status = TaskFormStatus.idle,
    this.isEditing = false,
    this.type = TaskType.task,
    this.title = '',
    this.description = '',
    this.priority = TaskPriority.medium,
    this.projectId,
    this.subtaskTitles = const [],
    this.recurrence = RecurrenceOption.none,
    this.reminders = const {},
    this.isAllDay = false,
    this.startAt,
    this.endAt,
    this.dueAt,
    this.projects = const [],
    this.errorMessage,
  });

  /// Tanggal acuan terisi (menentukan pengulangan & pengingat aktif).
  DateTime? get anchorDate {
    switch (type) {
      case TaskType.event:
      case TaskType.reminder:
        return startAt;
      case TaskType.task:
      case TaskType.milestone:
        return dueAt;
    }
  }

  bool get hasAnchorDate => anchorDate != null;

  /// Pengingat yang benar-benar disimpan: hanya bila tanggal terisi.
  List<int> get savedReminderOffsets {
    if (!hasAnchorDate) {
      return const [];
    }
    final offsets = reminders.map((r) => r.toOffsetMinutes()).toList()..sort();
    return offsets;
  }

  bool get canSave => title.trim().isNotEmpty;

  TaskFormState copyWith({
    TaskFormStatus? status,
    bool? isEditing,
    TaskType? type,
    String? title,
    String? description,
    TaskPriority? priority,
    String? projectId,
    bool clearProject = false,
    List<String>? subtaskTitles,
    RecurrenceOption? recurrence,
    Set<ReminderOption>? reminders,
    bool? isAllDay,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? dueAt,
    bool clearStartAt = false,
    bool clearEndAt = false,
    bool clearDueAt = false,
    List<Project>? projects,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskFormState(
      status: status ?? this.status,
      isEditing: isEditing ?? this.isEditing,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      projectId: clearProject ? null : (projectId ?? this.projectId),
      subtaskTitles: subtaskTitles ?? this.subtaskTitles,
      recurrence: recurrence ?? this.recurrence,
      reminders: reminders ?? this.reminders,
      isAllDay: isAllDay ?? this.isAllDay,
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      projects: projects ?? this.projects,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEditing,
        type,
        title,
        description,
        priority,
        projectId,
        subtaskTitles,
        recurrence,
        reminders,
        isAllDay,
        startAt,
        endAt,
        dueAt,
        projects,
        errorMessage,
      ];
}
