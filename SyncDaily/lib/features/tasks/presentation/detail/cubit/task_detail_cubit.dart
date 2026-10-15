import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';
import 'package:sync_daily/features/projects/domain/repositories/project_repository.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/entities/task_enums.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/presentation/detail/cubit/task_detail_state.dart';

/// Cubit layar detail tugas. Data tugas dan sub-tugas dimuat reaktif dari
/// `watchAllTasks()` sehingga perubahan status, centang sub-tugas, dan hasil
/// form ubah langsung terlihat.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  final String taskId;
  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<Project>>? _projectsSub;

  TaskDetailCubit({
    required this.taskId,
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        super(const TaskDetailState());

  void start() {
    unawaited(_tasksSub?.cancel());
    _tasksSub = _taskRepository.watchAllTasks().listen(
          _onTasks,
          onError: _onError,
        );
    unawaited(_projectsSub?.cancel());
    _projectsSub = _projectRepository.watchProjects().listen(
          (projects) => emit(state.copyWith(projects: projects)),
          onError: _onError,
        );
    unawaited(_loadExtras());
  }

  void _onTasks(List<Task> tasks) {
    Task? task;
    for (final item in tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }
    if (task == null) {
      emit(state.copyWith(
        status: TaskDetailStatus.notFound,
        clearTask: true,
        subtasks: const [],
      ));
      return;
    }
    final subtasks = tasks.where((t) => t.parentTaskId == taskId).toList();
    emit(state.copyWith(
      status: TaskDetailStatus.loaded,
      task: task,
      subtasks: subtasks,
    ));
  }

  /// Memuat ulang pengingat & pengulangan (dipanggil setelah kembali dari form
  /// ubah).
  Future<void> refresh() => _loadExtras();

  Future<void> _loadExtras() async {
    try {
      final reminders = await _taskRepository.getReminders(taskId);
      final recurrence = await _taskRepository.getRecurrence(taskId);
      emit(state.copyWith(
        reminders: reminders,
        recurrence: recurrence,
        clearRecurrence: recurrence == null,
      ));
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    }
  }

  /// Mengubah status item: selesai <-> belum selesai.
  Future<void> toggleStatus() async {
    final task = state.task;
    if (task == null) {
      return;
    }
    final next = task.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;
    await _taskRepository.setStatus(task.id, next);
  }

  /// Mencentang/membatalkan centang satu sub-tugas.
  Future<void> toggleSubtask(String subtaskId) async {
    Task? subtask;
    for (final item in state.subtasks) {
      if (item.id == subtaskId) {
        subtask = item;
        break;
      }
    }
    if (subtask == null) {
      return;
    }
    final next = subtask.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;
    await _taskRepository.setStatus(subtaskId, next);
  }

  /// Menghapus item beserta sub-tasknya. Mengembalikan id yang terhapus untuk
  /// aksi "Urungkan".
  Future<List<String>> delete() => _taskRepository.softDeleteTask(taskId);

  void _onError(Object error, StackTrace stackTrace) {
    emit(state.copyWith(
      status: TaskDetailStatus.error,
      errorMessage: '$error',
    ));
  }

  @override
  Future<void> close() async {
    await _tasksSub?.cancel();
    await _projectsSub?.cancel();
    return super.close();
  }
}
