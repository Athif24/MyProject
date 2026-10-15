import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/di/injection.dart';
import 'package:sync_daily/core/strings/app_strings.dart';
import 'package:sync_daily/core/theme/app_icons.dart';
import 'package:sync_daily/core/theme/app_sizes.dart';
import 'package:sync_daily/core/theme/app_typography.dart';
import 'package:sync_daily/core/widgets/app_icon_button.dart';
import 'package:sync_daily/core/widgets/empty_state.dart';
import 'package:sync_daily/core/widgets/latar_layar.dart';
import 'package:sync_daily/features/tasks/domain/entities/task.dart';
import 'package:sync_daily/features/tasks/domain/repositories/task_repository.dart';
import 'package:sync_daily/features/tasks/domain/task_list_filter.dart';
import 'package:sync_daily/features/tasks/presentation/list/cubit/task_list_cubit.dart';
import 'package:sync_daily/features/tasks/presentation/list/cubit/task_list_state.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_detail_flow.dart';
import 'package:sync_daily/features/tasks/presentation/widgets/task_tile.dart';

/// Daftar tugas sementara (F4b): pintu masuk menuju layar detail.
///
/// TODO(design): layar ini belum didesain. Memakai komponen dan token yang ada
/// (AppIconButton, EmptyState, TaskTile) sampai desain tersedia.
class TaskListPage extends StatelessWidget {
  final TaskListFilter filter;

  const TaskListPage({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskListCubit(
        taskRepository: getIt<TaskRepository>(),
        filter: filter,
      )..start(),
      child: const _TaskListView(),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView();

  String _title(TaskListFilter filter) => switch (filter) {
        TaskListFilter.today => AppStrings.taskListToday,
        TaskListFilter.allTasks => AppStrings.taskListAll,
      };

  Future<void> _openDetail(BuildContext context, Task task) {
    return openTaskDetailWithUndo(
      context: context,
      taskId: task.id,
      onUndo: (ids) => context.read<TaskListCubit>().restore(ids),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayarLatar(
        child: SafeArea(
          child: BlocBuilder<TaskListCubit, TaskListState>(
            builder: (context, state) => Column(
              children: [
                _Header(title: _title(state.filter)),
                Expanded(child: _Body(
                  state: state,
                  onOpenDetail: (task) => _openDetail(context, task),
                  onRetry: context.read<TaskListCubit>().start,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;

  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.cardGap,
        AppSizes.pagePadding,
        AppSizes.cardGap,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.back,
            semanticLabel: AppStrings.back,
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: AppSizes.cardGap),
          Expanded(
            child: Text(
              title,
              style: AppTypography.textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TaskListState state;
  final ValueChanged<Task> onOpenDetail;
  final VoidCallback onRetry;

  const _Body({
    required this.state,
    required this.onOpenDetail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case TaskListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case TaskListStatus.error:
        return _CenteredEmpty(
          title: AppStrings.loadFailedTitle,
          description: AppStrings.loadFailedDescription,
          action: FilledButton(
            onPressed: onRetry,
            child: Text(
              AppStrings.retry,
              style: AppTypography.textTheme.labelLarge,
            ),
          ),
        );
      case TaskListStatus.empty:
        return _CenteredEmpty(
          title: state.filter == TaskListFilter.today
              ? AppStrings.noTasksToday
              : AppStrings.noAllTasks,
          description: state.filter == TaskListFilter.today
              ? AppStrings.noTasksTodayDescription
              : AppStrings.noAllTasksDescription,
        );
      case TaskListStatus.loaded:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.sectionGap * 2,
          ),
          itemCount: state.tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.itemSpacing),
          itemBuilder: (context, index) {
            final task = state.tasks[index];
            return TaskTile(task: task, onTap: () => onOpenDetail(task));
          },
        );
    }
  }
}

class _CenteredEmpty extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? action;

  const _CenteredEmpty({required this.title, this.description, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: EmptyState(
          title: title,
          description: description,
          action: action,
        ),
      ),
    );
  }
}
