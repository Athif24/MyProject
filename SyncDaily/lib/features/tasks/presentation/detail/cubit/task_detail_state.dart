import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_recurrence.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_reminder.dart';

enum TaskDetailStatus {
  loading,
  loaded,

  /// Sedang menghapus item. Layar menampilkan keadaan netral (tanpa pesan
  /// galat) sampai halaman ditutup, supaya baris yang hilang dari aliran data
  /// tidak sempat memunculkan "Item tidak ditemukan".
  deleting,

  notFound,
  error,
}

/// Keadaan layar detail tugas (F4b).
class TaskDetailState extends Equatable {
  final TaskDetailStatus status;
  final Task? task;
  final List<Task> subtasks;
  final List<Project> projects;
  final List<TaskReminder> reminders;
  final TaskRecurrence? recurrence;
  final String? errorMessage;

  const TaskDetailState({
    this.status = TaskDetailStatus.loading,
    this.task,
    this.subtasks = const [],
    this.projects = const [],
    this.reminders = const [],
    this.recurrence,
    this.errorMessage,
  });

  bool get isDone => task?.status == TaskStatus.done;

  /// Judul proyek pemilik item, atau null bila tanpa proyek.
  String? get projectTitle {
    final projectId = task?.projectId;
    if (projectId == null) {
      return null;
    }
    for (final project in projects) {
      if (project.id == projectId) {
        return project.title;
      }
    }
    return null;
  }

  TaskDetailState copyWith({
    TaskDetailStatus? status,
    Task? task,
    List<Task>? subtasks,
    List<Project>? projects,
    List<TaskReminder>? reminders,
    TaskRecurrence? recurrence,
    String? errorMessage,
    bool clearTask = false,
    bool clearRecurrence = false,
    bool clearError = false,
  }) {
    return TaskDetailState(
      status: status ?? this.status,
      task: clearTask ? null : (task ?? this.task),
      subtasks: subtasks ?? this.subtasks,
      projects: projects ?? this.projects,
      reminders: reminders ?? this.reminders,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        task,
        subtasks,
        projects,
        reminders,
        recurrence,
        errorMessage,
      ];
}
