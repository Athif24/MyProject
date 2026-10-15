import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_list_filter.dart';
import 'package:sync_daily/features/tasks/presentation/list/cubit/task_list_state.dart';

/// Cubit daftar tugas sementara. Menyaring `watchAllTasks()` dengan kriteria
/// yang sama seperti angka kartu Beranda ([TaskListFilters]).
class TaskListCubit extends Cubit<TaskListState> {
  final TaskRepository _taskRepository;

  /// Sumber waktu; bisa diganti pada pengujian.
  final DateTime Function() _now;

  StreamSubscription<List<Task>>? _tasksSub;

  TaskListCubit({
    required TaskRepository taskRepository,
    required TaskListFilter filter,
    DateTime Function()? now,
  })  : _taskRepository = taskRepository,
        _now = now ?? DateTime.now,
        super(TaskListState(filter: filter));

  void start() {
    final today = _now();
    unawaited(_tasksSub?.cancel());
    _tasksSub = _taskRepository.watchAllTasks().listen(
      (tasks) {
        final filtered = tasks
            .where((task) => TaskListFilters.matches(task, state.filter, today))
            .toList();
        emit(
          state.copyWith(
            status: filtered.isEmpty
                ? TaskListStatus.empty
                : TaskListStatus.loaded,
            tasks: filtered,
          ),
        );
      },
      onError: (Object error) => emit(
        state.copyWith(
          status: TaskListStatus.error,
          errorMessage: '$error',
        ),
      ),
    );
  }

  /// Memulihkan item yang baru dihapus (aksi "Urungkan").
  Future<void> restore(List<String> ids) => _taskRepository.restoreTasks(ids);

  @override
  Future<void> close() async {
    await _tasksSub?.cancel();
    return super.close();
  }
}
