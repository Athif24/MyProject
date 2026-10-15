import 'package:equatable/equatable.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/task_list_filter.dart';

enum TaskListStatus { loading, loaded, empty, error }

/// Keadaan daftar tugas sementara (F4b).
class TaskListState extends Equatable {
  final TaskListStatus status;
  final TaskListFilter filter;
  final List<Task> tasks;
  final String? errorMessage;

  const TaskListState({
    this.status = TaskListStatus.loading,
    required this.filter,
    this.tasks = const [],
    this.errorMessage,
  });

  TaskListState copyWith({
    TaskListStatus? status,
    TaskListFilter? filter,
    List<Task>? tasks,
    String? errorMessage,
  }) {
    return TaskListState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, filter, tasks, errorMessage];
}
